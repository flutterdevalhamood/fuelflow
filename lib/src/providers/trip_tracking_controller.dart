import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class TripTrackingController with ChangeNotifier {
  final token = AuthRepo.token;

  // Private tracking variables - NOT exposed to UI
  bool _isTracking = false;
  Position? _lastPosition;
  int? _currentTripId;
  int? _currentTripStopId;

  Timer? _backgroundTimer;

  static const double distanceThreshold = 500.0; // 500 meters
  static const Duration backgroundCheckInterval = Duration(seconds: 30);

  // Only expose isTracking status (no location details)
  bool get isTracking => _isTracking;

  // Start trip tracking - completely silent to user
  Future<void> startTripTracking({
    required int tripId,
    int? tripStopId,
    required String eventType,
  }) async {
    if (_isTracking) return;

    try {
      // Store trip details privately
      _currentTripId = tripId;
      _currentTripStopId = tripStopId;

      // Check location permissions silently
      final permission = await _checkLocationPermission();
      if (!permission) {
        debugPrint('⚠️ Location permission denied');
        return;
      }

      // Log initial trip event (start_journey) in background - SILENT
      _logTripEventInBackground(
        tripId: tripId,
        tripStopId: tripStopId,
        eventType: eventType,
      );

      // Get initial position - PRIVATE, not shown to user
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _isTracking = true;
      notifyListeners(); // Only notify tracking status changed

      // Start silent background location tracking
      _startSilentBackgroundTracking(tripId, tripStopId);

      debugPrint('✅ Trip tracking started silently');
    } catch (e) {
      debugPrint('❌ Error starting trip tracking: $e');
    }
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return false;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  // Silent background tracking - completely hidden from user
  void _startSilentBackgroundTracking(int tripId, int? tripStopId) {
    _backgroundTimer = Timer.periodic(backgroundCheckInterval, (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }

      try {
        // Get current position silently - NO UI update
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint(' Location fetch timeout');
            return _lastPosition ??
                Position(
                  latitude: 0,
                  longitude: 0,
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0,
                  headingAccuracy: 0,
                );
          },
        );

        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            currentPosition.latitude,
            currentPosition.longitude,
          );

          // Console log for admin/debugging only
          debugPrint(
            '📏 Distance moved: ${distance.toStringAsFixed(2)} meters',
          );

          // Check if user has moved more than 500 meters
          if (distance >= distanceThreshold) {
            debugPrint(' Threshold reached! Logging trip event silently...');

            // Log trip event in background - COMPLETELY SILENT
            _logTripEventInBackground(
              tripId: tripId,
              tripStopId: tripStopId,
              eventType: 'moving_towards_next_stop',
              position: currentPosition,
            );

            // Update last position PRIVATELY (not shown to user)
            _lastPosition = currentPosition;

            // NO UI notification - tracking is invisible
          }
        } else {
          // First position update
          _lastPosition = currentPosition;
          debugPrint(' Initial position recorded');
        }
      } catch (e) {
        debugPrint(' Error checking position: $e');
        // Silent error - don't notify user
      }
    });
  }

  // Fire-and-forget API call - runs completely in background, invisible to user
  void _logTripEventInBackground({
    required int tripId,
    int? tripStopId,
    required String eventType,
    Position? position,
  }) {
    // Run in a separate async context to avoid blocking
    Future.microtask(() async {
      try {
        if (token == null) {
          debugPrint('⚠️ No token found for trip event');
          return;
        }

        // Get current position if not provided
        Position currentPosition;
        if (position != null) {
          currentPosition = position;
        } else {
          try {
            currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint('⚠️ Could not get position for trip event: $e');
            return;
          }
        }

        // Admin/Debug logging only - NOT shown to user
        debugPrint('📍 Logging trip event: $eventType');
        debugPrint(
          '   Location: ${currentPosition.latitude}, ${currentPosition.longitude}',
        );

        // Create a separate Dio instance for background calls to avoid interference
        final dio = Dio();
        final backgroundRestApi = RestClient(dio);

        // Make the API call without awaiting - FIRE AND FORGET
        backgroundRestApi
            .postLogTripEvent(
              tripId: tripId,
              token: 'Bearer $token',
              tripStopId: tripStopId,
              eventType: eventType,
              latitude: currentPosition.latitude.toString(),
              longitude: currentPosition.longitude.toString(),
            )
            .then((response) {
              // Success - log for admin only
              debugPrint('✅ Trip event logged: $eventType');
              debugPrint('   Response: $response');
            })
            .catchError((error) {
              // Error - log for admin only, NO user notification
              debugPrint('❌ Error logging trip event: $error');
              if (error is DioException) {
                debugPrint('   Type: ${error.type}');
                debugPrint('   Message: ${error.message}');
              }
            });
      } catch (e) {
        debugPrint('❌ Exception in background trip event logging: $e');
      }
    });
  }

  // Pause trip tracking (keeps position but stops checking)
  void pauseTripTracking() {
    _isTracking = false;
    _backgroundTimer?.cancel();
    notifyListeners(); // Only notify status changed
    debugPrint('⏸️ Trip tracking paused');
  }

  // Resume trip tracking
  void resumeTripTracking() {
    if (_currentTripId == null) {
      debugPrint('⚠️ Cannot resume: No trip ID stored');
      return;
    }

    _isTracking = true;
    _startSilentBackgroundTracking(_currentTripId!, _currentTripStopId);
    notifyListeners(); // Only notify status changed
    debugPrint('▶️ Trip tracking resumed');
  }

  // Stop trip tracking completely and log final event
  Future<void> stopTripTracking({String? finalEventType}) async {
    if (_currentTripId != null && finalEventType != null) {
      // Log final event before stopping - SILENT
      _logTripEventInBackground(
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
    notifyListeners(); // Only notify status changed
    debugPrint('🛑 Trip tracking stopped');
  }

  // Helper method to log specific trip events manually - SILENT
  Future<void> logManualTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null) {
      debugPrint('⚠️ Cannot log event: No active trip');
      return;
    }

    // Log event silently in background
    _logTripEventInBackground(
      tripId: _currentTripId!,
      tripStopId: _currentTripStopId,
      eventType: eventType,
    );

    debugPrint('📝 Manual event logged: $eventType');
  }

  @override
  void dispose() {
    stopTripTracking();
    super.dispose();
  }
}
