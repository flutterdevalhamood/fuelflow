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

  static const double distanceThreshold = 500.0; // meters
  static const Duration backgroundCheckInterval = Duration(seconds: 30);

  bool get isTracking => _isTracking;

  // ======================= START TRACKING =======================

  Future<void> startTripTracking({
    required int tripId,
    int? tripStopId,
    required String eventType,
  }) async {
    if (_isTracking) return;

    try {
      _currentTripId = tripId;
      _currentTripStopId = tripStopId;

      final permission = await _checkLocationPermission();
      if (!permission) return;

      _logTripEventInBackground(
        tripId: tripId,
        tripStopId: tripStopId,
        eventType: eventType,
      );

      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _isTracking = true;
      notifyListeners();

      _startSilentBackgroundTracking(tripId, tripStopId);

      debugPrint('✅ Trip tracking started');
    } catch (e) {
      debugPrint('❌ startTripTracking error: $e');
    }
  }

  // ======================= PERMISSION =======================

  Future<bool> _checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ======================= BACKGROUND TRACKING =======================

  void _startSilentBackgroundTracking(int tripId, int? tripStopId) {
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
            _logTripEventInBackground(
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

  // ======================= BACKGROUND LOGGER (UNCHANGED) =======================

  void _logTripEventInBackground({
    required int tripId,
    int? tripStopId,
    required String eventType,
    Position? position,
  }) {
    Future.microtask(() async {
      try {
        if (token == null) return;

        final pos =
            position ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 5));

        final dio = Dio();
        final api = RestClient(dio);

        api
            .postLogTripEvent(
              tripId: tripId,
              token: 'Bearer $token',
              tripStopId: tripStopId,
              eventType: eventType,
              latitude: pos.latitude.toString(),
              longitude: pos.longitude.toString(),
            )
            .then((_) {
              debugPrint('✅ Background event logged: $eventType');
            })
            .catchError((e) {
              debugPrint('❌ Background event failed: $e');
            });
      } catch (e) {
        debugPrint('❌ Background logger exception: $e');
      }
    });
  }

  Future<bool> logCriticalTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null || token == null) {
      debugPrint('❌ Critical event skipped: No trip/token');
      return false;
    }

    try {
      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        position = _lastPosition; // ✅ fallback for physical devices
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final api = RestClient(dio);

      await api.postLogTripEvent(
        tripId: _currentTripId!,
        token: 'Bearer $token',
        tripStopId: _currentTripStopId,
        eventType: eventType,
        latitude: position?.latitude.toString(),
        longitude: position?.longitude.toString(),
      );

      debugPrint('✅ CRITICAL event logged: $eventType');
      return true;
    } catch (e) {
      debugPrint('❌ CRITICAL event failed [$eventType]: $e');
      return false;
    }
  }

  Future<void> logManualTripEvent({
    required String eventType,
    String? description,
  }) async {
    if (_currentTripId == null) return;

    _logTripEventInBackground(
      tripId: _currentTripId!,
      tripStopId: _currentTripStopId,
      eventType: eventType,
    );
  }

  // ======================= CONTROL =======================

  void pauseTripTracking() {
    _isTracking = false;
    _backgroundTimer?.cancel();
    notifyListeners();
  }

  void resumeTripTracking() {
    if (_currentTripId == null) return;
    _isTracking = true;
    _startSilentBackgroundTracking(_currentTripId!, _currentTripStopId);
    notifyListeners();
  }

  Future<void> stopTripTracking({String? finalEventType}) async {
    if (_currentTripId != null && finalEventType != null) {
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
    notifyListeners();
  }

  @override
  void dispose() {
    stopTripTracking();
    super.dispose();
  }
}
