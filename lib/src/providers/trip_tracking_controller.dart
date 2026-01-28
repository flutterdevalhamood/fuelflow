import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/rest_client.dart';
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

  static const double distanceThreshold = 5.0; // meters for location logging
  static const Duration locationLogInterval = Duration(
    seconds: 30,
  ); // Check interval

  bool get isTracking => _isTracking;

  // Track pending API calls to prevent duplicates
  final Set<String> _pendingLocationLogs = {};
  final Set<String> _pendingEventLogs = {};

  Future<void> startTripTracking({
    required int tripId,
    int? tripStopId,
    required String eventType,
    int? driverId,
    int? vehicleId,
  }) async {
    // Store driver and vehicle IDs for location logging
    _driverId = driverId;
    _vehicleId = vehicleId;

    // Check if we're already tracking this exact stop
    if (_isTracking &&
        _currentTripId == tripId &&
        _currentTripStopId == tripStopId) {
      debugPrint('⚠️ Already tracking trip $tripId, stop $tripStopId');
      return;
    }

    // If tracking a different stop in the same trip, stop current tracking first
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

      // Get initial position
      try {
        _lastPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ Could not get initial position: $e');
        // Continue without position - will try again in background
      }

      _isTracking = true;
      notifyListeners();

      // 1. Log the initial event using LogTripEvent API
      await _logTripEventSynchronously(
        tripId: tripId,
        tripStopId: tripStopId,
        eventType: eventType,
        position: _lastPosition,
      );

      // 2. Start background location logging based on distance
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
        // Use better location settings for physical device
        final LocationSettings locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Only update when moved 5 meters
          forceLocationManager: false, // Use Google Play Services
          intervalDuration: const Duration(seconds: 30),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Tracking your trip location",
            notificationTitle: "Trip Active",
            enableWakeLock: true,
          ),
        );

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

  // ======================= LOCATION LOGGING (LogTripLocations API) =======================

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

    // FIX: Use AuthRepo.driverId as fallback
    final driverId = _driverId ?? AuthRepo.driverId;

    if (driverId == null) {
      debugPrint('❌ Driver ID not available for location logging');
      return false;
    }

    // FIX: Don't block if vehicle ID is null - just log warning
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
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final api = RestClient(dio);

      debugPrint('🌐 Sending location to API...');

      await api.postLogTripLocations(
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
  // ======================= EVENT LOGGING (LogTripEvent API) =======================

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

    // Create unique key for this event log to prevent duplicates
    final eventKey = 'event_${tripId}_${tripStopId}_$eventType';
    if (_pendingEventLogs.contains(eventKey)) {
      debugPrint('⚠️ Event $eventType already in progress');
      return false;
    }

    _pendingEventLogs.add(eventKey);

    try {
      Position? pos = position;

      // Try to get current position if not provided
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

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final api = RestClient(dio);

      await api.postLogTripEvent(
        tripId: tripId,
        token: 'Bearer $token',
        tripStopId: tripStopId,
        eventType: eventType,
        latitude: pos?.latitude.toString(),
        longitude: pos?.longitude.toString(),
      );

      debugPrint(
        '✅ Event logged via LogTripEvent: $eventType (trip: $tripId, stop: $tripStopId)',
      );
      _pendingEventLogs.remove(eventKey);
      return true;
    } catch (e) {
      debugPrint('❌ Event logging via LogTripEvent failed [$eventType]: $e');

      // Retry logic
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

  // ======================= PUBLIC EVENT LOGGERS (For manual events) =======================

  Future<bool> logCriticalTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null) {
      debugPrint('❌ Critical event skipped: No active trip');
      return false;
    }

    debugPrint('🔴 CRITICAL EVENT via LogTripEvent: $eventType');

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

    debugPrint('📝 Manual event via LogTripEvent: $eventType');

    return await _logTripEventSynchronously(
      tripId: _currentTripId!,
      tripStopId: _currentTripStopId,
      eventType: eventType,
    );
  }

  // ======================= CONTROL METHODS =======================

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
      // Log final event using LogTripEvent API
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
