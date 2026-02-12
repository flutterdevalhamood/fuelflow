import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sample/src/data/rest_client.dart';

import '../repo/auth_repo.dart';

class TripTrackingController with ChangeNotifier {
  final token = AuthRepo.token;

  bool _isTracking = false;
  Position? _lastPosition;
  int? _currentTripId;
  int? _currentTripStopId;
  int? _driverId;
  int? _vehicleId;

  Timer? _locationLoggerTimer;
  Timer? _backgroundPositionChecker;

  int? get currentTripId => _currentTripId;

  static const double distanceThreshold = 5.0;
  static const Duration locationLogInterval = Duration(seconds: 30);

  bool get isTracking => _isTracking;

  final Set<String> _pendingLocationLogs = {};
  final Set<String> _pendingEventLogs = {};

  Future<void> startTripTracking({
    required int tripId,
    int? tripStopId,
    required String eventType,
    int? driverId,
    int? vehicleId,
  }) async {
    _driverId = driverId;
    _vehicleId = vehicleId;

    if (_isTracking &&
        _currentTripId == tripId &&
        _currentTripStopId == tripStopId) {
      debugPrint('⚠️ Already tracking trip $tripId, stop $tripStopId');
      return;
    }

    if (_isTracking &&
        _currentTripId == tripId &&
        _currentTripStopId != tripStopId) {
      debugPrint('🔄 Switching to new stop: $tripStopId');
      await stopTripTracking();
    }

    try {
      _currentTripId = tripId;
      _currentTripStopId = tripStopId;

      final permission = await checkLocationPermission();
      if (!permission) {
        debugPrint('❌ Location permission denied');
        return;
      }

      try {
        _lastPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ Could not get initial position: $e');
      }

      _isTracking = true;
      notifyListeners();

      await _logTripEventSynchronously(
        tripId: tripId,
        tripStopId: tripStopId,
        eventType: eventType,
        position: _lastPosition,
      );

      _startBackgroundLocationLogging(tripId);

      debugPrint('✅ Trip tracking started for trip $tripId, stop $tripStopId');
    } catch (e) {
      debugPrint('❌ startTripTracking error: $e');
      _isTracking = false;
      notifyListeners();
    }
  }

  Future<bool> checkLocationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('❌ Location services disabled');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
      return false;
    }
  }

  void _startBackgroundLocationLogging(int tripId) {
    _locationLoggerTimer?.cancel();
    _backgroundPositionChecker?.cancel();

    _backgroundPositionChecker = Timer.periodic(locationLogInterval, (
      timer,
    ) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings:
              Platform.isAndroid
                  ? AndroidSettings(
                    accuracy: LocationAccuracy.high,
                    distanceFilter: 5,
                    forceLocationManager: false,
                    intervalDuration: const Duration(seconds: 30),
                    foregroundNotificationConfig:
                        const ForegroundNotificationConfig(
                          notificationText: "Tracking your trip location",
                          notificationTitle: "Trip Active",
                          enableWakeLock: true,
                        ),
                  )
                  : AppleSettings(
                    accuracy: LocationAccuracy.high,
                    distanceFilter: 5,
                    activityType: ActivityType.automotiveNavigation,
                  ),
        ).timeout(const Duration(seconds: 10));

        bool shouldLogLocation = false;

        if (_lastPosition == null) {
          shouldLogLocation = true;
          debugPrint('📍 First position captured');
        } else {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPosition.latitude,
            currentPosition.longitude,
          );

          debugPrint('📏 Distance moved: ${distance.toStringAsFixed(2)}m');

          if (distance >= distanceThreshold) {
            shouldLogLocation = true;
            debugPrint('✅ Distance threshold met, logging location');
          } else {
            debugPrint('⏭️ Distance too small, skipping log');
          }
        }

        if (shouldLogLocation) {
          final success = await _logTripLocationSynchronously(
            tripId: tripId,
            position: currentPosition,
          );

          if (success) {
            _lastPosition = currentPosition;
          }
        }
      } catch (e) {
        debugPrint('❌ Background location check error: $e');
      }
    });
  }

  // ✅ UPDATED: Use global restApi instead of creating new Dio instance
  Future<bool> _logTripLocationSynchronously({
    required int tripId,
    required Position position,
    int retries = 2,
  }) async {
    debugPrint('🔵 Attempting to log location for trip $tripId');
    debugPrint('   Driver ID: $_driverId');
    debugPrint('   Vehicle ID: $_vehicleId');
    debugPrint('   Lat: ${position.latitude}, Lng: ${position.longitude}');

    if (token == null) {
      debugPrint('❌ No token available for location logging');
      return false;
    }

    final driverId = _driverId ?? AuthRepo.driverId;

    if (driverId == null) {
      debugPrint('❌ Driver ID not available for location logging');
      return false;
    }

    if (_vehicleId == null) {
      debugPrint('⚠️ Vehicle ID not set for location logging');
    }

    final locationKey =
        'loc_${tripId}_${position.latitude}_${position.longitude}_${DateTime.now().millisecondsSinceEpoch}';

    if (_pendingLocationLogs.contains(locationKey)) {
      debugPrint('⚠️ Location logging already in progress');
      return false;
    }

    _pendingLocationLogs.add(locationKey);

    try {
      debugPrint('🌐 Sending location to API...');

      // ✅ USE GLOBAL restApi INSTANCE
      await restApi.postLogTripLocations(
        tripId: tripId,
        token: 'Bearer $token',
        driverId: driverId,
        vehicleId: _vehicleId,
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );

      debugPrint('✅ Location logged successfully');
      _pendingLocationLogs.remove(locationKey);
      return true;
    } catch (e) {
      debugPrint('❌ Location logging failed: $e');

      if (retries > 0) {
        debugPrint('🔄 Retrying... ($retries attempts left)');
        await Future.delayed(const Duration(seconds: 2));
        _pendingLocationLogs.remove(locationKey);
        return await _logTripLocationSynchronously(
          tripId: tripId,
          position: position,
          retries: retries - 1,
        );
      }

      _pendingLocationLogs.remove(locationKey);
      return false;
    }
  }

  Future<bool> _logTripEventSynchronously({
    required int tripId,
    int? tripStopId,
    required String eventType,
    Position? position,
    int retries = 2,
  }) async {
    if (token == null) {
      debugPrint('❌ No token available for event logging');
      return false;
    }

    final eventKey = 'event_${tripId}_${tripStopId}_$eventType';
    if (_pendingEventLogs.contains(eventKey)) {
      debugPrint('⚠️ Event $eventType already in progress');
      return false;
    }

    _pendingEventLogs.add(eventKey);

    try {
      Position? pos = position;

      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('⚠️ Using last known position for $eventType');
          pos = _lastPosition;
        }
      }

      debugPrint('🔵 Logging event: $eventType');
      debugPrint('   Trip ID: $tripId, Stop ID: $tripStopId');

      // ✅ USE GLOBAL restApi INSTANCE
      await restApi.postLogTripEvent(
        tripId: tripId,
        token: 'Bearer $token',
        tripStopId: tripStopId,
        eventType: eventType,
        description: null,
        latitude: pos?.latitude.toString(),
        longitude: pos?.longitude.toString(),
      );

      debugPrint('✅ Event logged: $eventType');
      _pendingEventLogs.remove(eventKey);
      return true;
    } catch (e) {
      debugPrint('❌ Event logging failed [$eventType]: $e');

      if (retries > 0) {
        debugPrint('🔄 Retrying $eventType (${retries} attempts left)');
        await Future.delayed(const Duration(seconds: 2));
        _pendingEventLogs.remove(eventKey);
        return await _logTripEventSynchronously(
          tripId: tripId,
          tripStopId: tripStopId,
          eventType: eventType,
          position: position,
          retries: retries - 1,
        );
      }

      _pendingEventLogs.remove(eventKey);
      return false;
    }
  }

  Future<bool> logCriticalTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null) {
      debugPrint('❌ Critical event skipped: No active trip');
      return false;
    }

    debugPrint('🔴 CRITICAL EVENT: $eventType');

    return await _logTripEventSynchronously(
      tripId: _currentTripId!,
      tripStopId: _currentTripStopId,
      eventType: eventType,
    );
  }

  Future<bool> logManualTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null) {
      debugPrint('❌ Manual event skipped: No active trip');
      return false;
    }

    debugPrint('📝 Manual event: $eventType');

    return await _logTripEventSynchronously(
      tripId: _currentTripId!,
      tripStopId: _currentTripStopId,
      eventType: eventType,
    );
  }

  // ✅ UPDATED: Use global restApi instead of creating new Dio instance
  Future<Map<String, dynamic>> requestAdminVehicleRefilingForShortage({
    required String vehicleId,
    required double expectedQuantity,
    required Position position,
    String? notes,
  }) async {
    debugPrint('🚀 Requesting admin refill for vehicle $vehicleId');

    if (token == null) {
      debugPrint('❌ No token available for admin refill request');
      return {
        'success': false,
        'message': 'Authentication token not available',
      };
    }

    try {
      // ✅ USE GLOBAL restApi INSTANCE
      final response = await restApi.requestAdminVehicleRefilingForShortage(
        token: 'Bearer $token',
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        expectedQuantity: expectedQuantity.toString(),
        notes: notes,
        vehicleId: vehicleId,
      );

      debugPrint('✅ Admin refill request submitted successfully');

      return {
        'success': true,
        'message': 'Admin refill request sent successfully',
        'data': response,
      };
    } catch (e) {
      debugPrint('❌ Admin refill request failed: $e');

      String errorMessage = 'Failed to send request to server';
      if (e is DioException && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          errorMessage =
              errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorMessage;
        }
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }

  void pauseTripTracking() {
    _isTracking = false;
    _backgroundPositionChecker?.cancel();
    _locationLoggerTimer?.cancel();
    notifyListeners();
    debugPrint('⏸️ Trip tracking paused');
  }

  void resumeTripTracking() {
    if (_currentTripId == null) return;
    _isTracking = true;
    _startBackgroundLocationLogging(_currentTripId!);
    notifyListeners();
    debugPrint('▶️ Trip tracking resumed');
  }

  Future<void> stopTripTracking({String? finalEventType}) async {
    if (_currentTripId != null && finalEventType != null) {
      await _logTripEventSynchronously(
        tripId: _currentTripId!,
        tripStopId: _currentTripStopId,
        eventType: finalEventType,
      );
    }

    _isTracking = false;
    _backgroundPositionChecker?.cancel();
    _locationLoggerTimer?.cancel();
    _lastPosition = null;
    _currentTripId = null;
    _currentTripStopId = null;
    _driverId = null;
    _vehicleId = null;
    _pendingEventLogs.clear();
    _pendingLocationLogs.clear();
    notifyListeners();

    debugPrint('⏹️ Trip tracking stopped');
  }

  @override
  void dispose() {
    stopTripTracking();
    super.dispose();
  }
}
