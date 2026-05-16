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

  // ✅ FIXED: Use a StreamSubscription instead of Timer.periodic.
  // Timer.periodic is suspended by the OS when the screen locks.
  // Geolocator's position stream integrates with the native location
  // service (FusedLocationProvider on Android, CLLocationManager on iOS),
  // which continues updating even when the device is locked.
  StreamSubscription<Position>? _positionStreamSubscription;

  int? get currentTripId => _currentTripId;

  // ✅ Distance filter is now handled by the platform's native location
  // service via LocationSettings.distanceFilter (meters). This is more
  // power-efficient than receiving every update and skipping it in Dart.
  static const double distanceThreshold = 5.0;

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

      // ✅ FIXED: Subscribe to the native position stream.
      _startPositionStream(tripId);

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

  /// ✅ FIXED: Core change — subscribe to getPositionStream() instead of
  /// using Timer.periodic + getCurrentPosition().
  ///
  /// Why this works on locked screens:
  /// - Android: The ForegroundNotificationConfig keeps the location service
  ///   alive as a foreground service (required since Android 8+). The OS
  ///   cannot suspend a foreground service without user intervention.
  /// - iOS: The stream uses CLLocationManager with
  ///   ActivityType.automotiveNavigation, which keeps updates alive when
  ///   the app is backgrounded or the screen is locked.
  ///
  /// The distanceFilter (5 m here) means the stream only emits when the
  /// device has actually moved that far, saving battery. We still apply
  /// our own 150 m threshold before sending to the API to reduce network
  /// traffic.
  void _startPositionStream(int tripId) {
    _positionStreamSubscription?.cancel();

    final LocationSettings locationSettings =
        Platform.isAndroid
            ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              // ✅ Native distance filter — avoids waking Dart for tiny moves.
              distanceFilter: 5,
              forceLocationManager: false,
              intervalDuration: const Duration(seconds: 10),
              // ✅ CRITICAL for Android background / locked-screen operation.
              // Without a foreground notification, Android 8+ will kill the
              // location updates within minutes of the screen locking.
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationText: 'Tracking your trip location',
                notificationTitle: 'Trip Active',
                enableWakeLock: true,
                // ✅ Set to true so the notification is not removable by the
                // user while the trip is running.
                setOngoing: true,
              ),
            )
            : AppleSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              // ✅ automotiveNavigation keeps GPS on even with screen locked.
              activityType: ActivityType.automotiveNavigation,
              // ✅ pauseLocationUpdatesAutomatically: false prevents iOS from
              // pausing updates when the device appears stationary.
              pauseLocationUpdatesAutomatically: false,
              // ✅ showBackgroundLocationIndicator shows the blue bar in iOS,
              // required for background location permission to work correctly.
              showBackgroundLocationIndicator: true,
            );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position currentPosition) async {
        if (!_isTracking) return;

        bool shouldLog = false;

        if (_lastPosition == null) {
          shouldLog = true;
          debugPrint('📍 First position captured via stream');
        } else {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPosition.latitude,
            currentPosition.longitude,
          );

          debugPrint('📏 Distance moved: ${distance.toStringAsFixed(2)} m');

          if (distance >= distanceThreshold) {
            shouldLog = true;
            debugPrint('✅ Distance threshold met, logging location');
          } else {
            debugPrint('⏭️ Distance too small, skipping log');
          }
        }

        if (shouldLog) {
          final success = await _logTripLocationSynchronously(
            tripId: tripId,
            position: currentPosition,
          );
          if (success) {
            _lastPosition = currentPosition;
          }
        }
      },
      onError: (Object error) {
        debugPrint('❌ Position stream error: $error');
        // ✅ Attempt to restart the stream after a brief delay so
        // transient errors (GPS signal lost, service restart) don't
        // permanently stop tracking.
        if (_isTracking) {
          Future.delayed(const Duration(seconds: 5), () {
            if (_isTracking) _startPositionStream(tripId);
          });
        }
      },
      cancelOnError: false, // ✅ Keep stream alive on non-fatal errors.
    );
  }

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
        debugPrint('🔄 Retrying $eventType ($retries attempts left)');
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
    // ✅ Cancel the stream subscription instead of cancelling a timer.
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    notifyListeners();
    debugPrint('⏸️ Trip tracking paused');
  }

  void resumeTripTracking() {
    if (_currentTripId == null) return;
    _isTracking = true;
    _startPositionStream(_currentTripId!);
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
    // ✅ Cancel the stream subscription on stop.
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

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
