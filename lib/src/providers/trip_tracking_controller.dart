import 'dart:async';

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

  Timer? _backgroundTimer;

  static const double distanceThreshold = 5.0; // meters
  static const Duration backgroundCheckInterval = Duration(seconds: 30);

  bool get isTracking => _isTracking;

  final Set<String> _pendingEvents = {};

  Future<void> startTripTracking({
    required int tripId,
    int? tripStopId,
    required String eventType,
  }) async {
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

      final permission = await _checkLocationPermission();
      if (!permission) {
        debugPrint('❌ Location permission denied');
        return;
      }

      // Get initial position with timeout
      try {
        _lastPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ Could not get initial position: $e');
        // Continue without position - will try again
      }

      _isTracking = true;
      notifyListeners();

      // Log the initial event synchronously
      await _logTripEventSynchronously(
        tripId: tripId,
        tripStopId: tripStopId,
        eventType: eventType,
        position: _lastPosition,
      );

      _startSilentBackgroundTracking(tripId, tripStopId);

      debugPrint('✅ Trip tracking started for trip $tripId, stop $tripStopId');
    } catch (e) {
      debugPrint('❌ startTripTracking error: $e');
      _isTracking = false;
      notifyListeners();
    }
  }

  Future<bool> _checkLocationPermission() async {
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

  void _startSilentBackgroundTracking(int tripId, int? tripStopId) {
    _backgroundTimer?.cancel();

    _backgroundTimer = Timer.periodic(backgroundCheckInterval, (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));

        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPosition.latitude,
            currentPosition.longitude,
          );

          if (distance >= distanceThreshold) {
            await _logTripEventSynchronously(
              tripId: tripId,
              tripStopId: tripStopId,
              eventType: 'moving_towards_next_stop',
              position: currentPosition,
            );

            _lastPosition = currentPosition;
          }
        } else {
          _lastPosition = currentPosition;
        }
      } catch (e) {
        debugPrint('❌ Background tracking error: $e');
      }
    });
  }

  // ======================= SYNCHRONOUS EVENT LOGGER =======================

  Future<bool> _logTripEventSynchronously({
    required int tripId,
    int? tripStopId,
    required String eventType,
    Position? position,
    int retries = 2,
  }) async {
    if (token == null) {
      debugPrint('❌ No token available');
      return false;
    }

    // Prevent duplicate simultaneous calls
    final eventKey = '${tripId}_${tripStopId}_$eventType';
    if (_pendingEvents.contains(eventKey)) {
      debugPrint('⚠️ Event $eventType already in progress');
      return false;
    }

    _pendingEvents.add(eventKey);

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
        '✅ Event logged: $eventType (trip: $tripId, stop: $tripStopId)',
      );
      _pendingEvents.remove(eventKey);
      return true;
    } catch (e) {
      debugPrint('❌ Event logging failed [$eventType]: $e');

      // Retry logic
      if (retries > 0) {
        debugPrint('🔄 Retrying $eventType (${retries} attempts left)');
        await Future.delayed(const Duration(seconds: 2));
        _pendingEvents.remove(eventKey);
        return await _logTripEventSynchronously(
          tripId: tripId,
          tripStopId: tripStopId,
          eventType: eventType,
          position: position,
          retries: retries - 1,
        );
      }

      _pendingEvents.remove(eventKey);
      return false;
    }
  }

  // ======================= PUBLIC EVENT LOGGERS =======================

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

  // ======================= BATCH LOGGING =======================

  Future<void> logMultipleEvents(List<String> eventTypes) async {
    if (_currentTripId == null) return;

    for (final eventType in eventTypes) {
      await _logTripEventSynchronously(
        tripId: _currentTripId!,
        tripStopId: _currentTripStopId,
        eventType: eventType,
      );

      // Small delay between events
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ======================= CONTROL =======================

  void pauseTripTracking() {
    _isTracking = false;
    _backgroundTimer?.cancel();
    notifyListeners();
    debugPrint('⏸️ Trip tracking paused');
  }

  void resumeTripTracking() {
    if (_currentTripId == null) return;
    _isTracking = true;
    _startSilentBackgroundTracking(_currentTripId!, _currentTripStopId);
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
    _backgroundTimer?.cancel();
    _lastPosition = null;
    _currentTripId = null;
    _currentTripStopId = null;
    _pendingEvents.clear();
    notifyListeners();

    debugPrint('⏹️ Trip tracking stopped');
  }

  @override
  void dispose() {
    stopTripTracking();
    super.dispose();
  }
}
