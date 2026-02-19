import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/fuelTrip/all_vehicle_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class TripStartedScreen extends StatefulWidget {
  final int tripId;
  final int? tripStopId;
  final String customerName;
  final String arrivalTime;
  final int assignmentId;
  final int vehicleId;
  final double requiredQty;
  final double availableQty;
  final String vehicleName;
  final String stopOrder;
  final int currentStopIndex;
  final int totalStops;

  final int driverId;
  final String? siteName;
  final List<dynamic>? stopVehicles;
  final double? stopLatitude;
  final double? stopLongitude;

  const TripStartedScreen({
    super.key,
    required this.tripId,
    this.tripStopId,
    required this.customerName,
    required this.arrivalTime,
    required this.assignmentId,
    required this.vehicleId,
    required this.requiredQty,
    required this.availableQty,
    required this.vehicleName,
    required this.stopOrder,
    required this.currentStopIndex,
    required this.totalStops,
    required this.driverId,
    this.siteName,
    this.stopVehicles,
    this.stopLatitude,
    this.stopLongitude,
  });

  @override
  State<TripStartedScreen> createState() => _TripStartedScreenState();
}

class _TripStartedScreenState extends State<TripStartedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _truckAnimation;
  bool _isLocationReady = false;
  bool _isCheckingLocation = false;
  bool _hasShownLocationDialog = false;
  bool _isNavigating = false;

  GoogleMapController? _googleMapController;
  bool _mapExpanded = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _truckAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    print('vehicleidddddd  ${widget.vehicleId}');

    _checkExistingTracking();
  }

  Future<void> _checkExistingTracking() async {
    final controller = context.read<TripTrackingController>();

    if (controller.isTracking && controller.currentTripId == widget.tripId) {
      debugPrint('✅ Trip tracking already active for trip ${widget.tripId}');

      final hasPermission = await _quickLocationCheck();

      if (hasPermission) {
        setState(() {
          _isLocationReady = true;
          _isCheckingLocation = false;
        });
        _animationController.repeat(reverse: true);

        if (controller.currentTripId == widget.tripId) {
          await _updateTripStop();
        }
      } else {
        await _setupTripWithLocation();
      }
    } else {
      await _setupTripWithLocation();
    }
  }

  Future<bool> _quickLocationCheck() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ Quick location check error: $e');
      return false;
    }
  }

  Future<void> _updateTripStop() async {
    try {
      final controller = context.read<TripTrackingController>();
      final driverId = AuthRepo.driverId;

      await controller.logManualTripEvent(
        eventType: 'start_journey',
        description: 'Started journey to ${widget.customerName}',
      );

      debugPrint('✅ Updated to new trip stop ${widget.tripStopId}');
    } catch (e) {
      debugPrint('❌ Error updating trip stop: $e');
    }
  }

  Future<void> _setupTripWithLocation() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _showLocationRequiredDialog();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          _startLocationMonitoring();
          return;
        }
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionSettingsDialog();
        _startLocationMonitoring();
        return;
      }

      if (permission == LocationPermission.whileInUse) {
        if (await _shouldRequestBackgroundPermission()) {
          await _requestBackgroundPermission();
        }
      }

      final hasValidPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!hasValidPermission) {
        _startLocationMonitoring();
        return;
      }

      await _startTripTracking();

      setState(() {
        _isLocationReady = true;
        _isCheckingLocation = false;
      });

      _animationController.repeat(reverse: true);
    } catch (e) {
      print('❌ Error setting up trip: $e');
      setState(() {
        _isCheckingLocation = false;
      });
      _startLocationMonitoring();
    }
  }

  Future<bool> _shouldRequestBackgroundPermission() async {
    return true;
  }

  Future<void> _requestBackgroundPermission() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Background Location'),
            content: const Text(
              'To track your trip accurately, please allow location access "All the time" in the next screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.requestPermission();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final destination = '$lat,$lng';
    final label = Uri.encodeComponent(widget.siteName ?? widget.customerName);

    // Try Google Maps first, fallback to browser
    final googleMapsUrl = Uri.parse('google.navigation:q=$destination&mode=d');
    final googleMapsFallback = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&destination_place_name=$label&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      await launchUrl(googleMapsFallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showLocationRequiredDialog() async {
    if (_hasShownLocationDialog) return;
    _hasShownLocationDialog = true;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on, size: 30, color: Colors.blue),
                SizedBox(width: 10),
                Text('Location Required'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To continue your trip, please enable location services.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateBack();
                },
                child: const Text('Cancel Trip'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Enable Location'),
              ),
            ],
          ),
    );
  }

  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.settings, size: 30, color: Colors.blue),
                SizedBox(width: 10),
                Text('Location Permission'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please grant location permission to continue your trip.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Go to Settings > Apps > [Your App] > Permissions',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateBack();
                },
                child: const Text('Cancel Trip'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  void _startLocationMonitoring() {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isLocationReady) {
        timer.cancel();
        return;
      }

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        var permission = await Geolocator.checkPermission();

        final hasValidPermission =
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;

        if (serviceEnabled && hasValidPermission) {
          timer.cancel();
          if (mounted) {
            await _startTripTracking();
            setState(() {
              _isLocationReady = true;
              _isCheckingLocation = false;
            });
            _animationController.repeat(reverse: true);
          }
        }
      } catch (e) {
        print('❌ Location monitoring error: $e');
      }
    });
  }

  Future<void> _startTripTracking() async {
    try {
      final controller = context.read<TripTrackingController>();
      final driverId = AuthRepo.driverId;

      await controller.startTripTracking(
        tripId: widget.tripId,
        tripStopId: widget.tripStopId,
        eventType: 'start_journey',
        driverId: driverId,
        vehicleId: widget.vehicleId,
      );

      print('✅ Trip tracking started for trip ${widget.tripId}');
    } catch (e) {
      print('❌ Error starting trip tracking: $e');
      rethrow;
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ✅ NEW: Handle SOS button click
  Future<void> _handleSOS(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Emergency SOS'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you in an emergency situation?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  'This will immediately notify the admin team of your emergency.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send SOS'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = AuthRepo.token;

      if (token == null) {
        throw Exception('Authentication token not available');
      }

      await restApi.getDriverSOS(token: 'Bearer $token');

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SOS alert sent successfully. Help is on the way.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ SOS request failed: $e');

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to send SOS: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ NEW: Handle Request Callback button click
  Future<void> _handleRequestCallback(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.phone_callback, color: Colors.orange, size: 30),
                SizedBox(width: 12),
                Text('Request Callback'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request admin to call you back?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  'An admin will contact you as soon as possible.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Request Call'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = AuthRepo.token;

      if (token == null) {
        throw Exception('Authentication token not available');
      }

      await restApi.getRequestAdminCallback(token: 'Bearer $token');

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Callback request sent. Admin will contact you soon.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Callback request failed: $e');

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to request callback: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _googleMapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStopLocationMap() {
    final lat = widget.stopLatitude;
    final lng = widget.stopLongitude;

    if (lat == null || lng == null) return const SizedBox.shrink();

    final stopLocation = LatLng(lat, lng);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Destination',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _mapExpanded = !_mapExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _mapExpanded ? 'Collapse' : 'Expand',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _mapExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _mapExpanded ? 300 : 180,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: stopLocation,
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _googleMapController = controller;
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('stop_location'),
                    position: stopLocation,
                    infoWindow: InfoWindow(
                      title: widget.siteName ?? widget.customerName,
                      snippet: 'Delivery Stop',
                    ),
                  ),
                },
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                // ✅ FIX: Claim all gestures so map gets touch priority over ScrollView
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  // Center button
                  GestureDetector(
                    onTap:
                        () => _googleMapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(stopLocation, 14.0),
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Center',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ NEW: Directions button
                  GestureDetector(
                    onTap: () => _openDirections(lat, lng),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.navigation, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Directions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Cancel Trip?'),
                content: const Text(
                  'Are you sure you want to cancel this trip?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continue Trip'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Trip'),
                  ),
                ],
              ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          final shouldPop = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Cancel Trip?'),
                                  content: const Text(
                                    'Are you sure you want to cancel this trip?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Continue Trip'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Cancel Trip'),
                                    ),
                                  ],
                                ),
                          );
                          if (shouldPop == true && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip In Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stop ${widget.currentStopIndex + 1} of ${widget.totalStops}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCheckingLocation)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else if (!_isLocationReady)
                        const Icon(
                          Icons.location_off,
                          color: Colors.orange,
                          size: 24,
                        )
                      else
                        const Icon(
                          Icons.location_on,
                          color: Colors.greenAccent,
                          size: 24,
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Status/animation section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isCheckingLocation)
                                  _buildCheckingLocationContent()
                                else if (!_isLocationReady)
                                  _buildLocationRequiredContent()
                                else
                                  _buildTripActiveContent(),
                              ],
                            ),
                          ),
                        ),
                        // Trip details card
                        if (_isLocationReady) _buildTripDetailsCard(),
                        // ✅ Map
                        if (_isLocationReady &&
                            widget.stopLatitude != null &&
                            widget.stopLongitude != null)
                          _buildStopLocationMap(),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLocationReady
                                  ? () => _handleArrival(context)
                                  : null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Arrived at Customer Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isLocationReady ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ NEW: SOS and Request Callback Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleSOS(context),
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text('SOS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleRequestCallback(context),
                              icon: const Icon(Icons.phone_callback),
                              label: const Text('Request Callback'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (!_isLocationReady)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _setupTripWithLocation,
                            icon: const Icon(Icons.location_on),
                            label: const Text('Enable Location to Start Trip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckingLocationContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
        const SizedBox(height: 30),
        const Text(
          'Setting Up Your Trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Checking location services...',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLocationRequiredContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on,
          size: 100,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(height: 30),
        const Text(
          'Location Required',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Please enable location services to start your trip.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _setupTripWithLocation,
          icon: const Icon(Icons.location_on),
          label: const Text('Enable Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildTripActiveContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _truckAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset((_truckAnimation.value - 0.5) * 100, 0),
              child: Transform.scale(
                scale: 1.0 + (_truckAnimation.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(backgroundColor: Colors.greenAccent, radius: 6),
              SizedBox(width: 8),
              Text(
                'En Route - Trip Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTripDetailsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Name',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.access_time,
            label: 'Expected Arrival',
            value:
                widget.arrivalTime.isNotEmpty ? widget.arrivalTime : 'Not Set',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.local_gas_station,
            label: 'Delivery Quantity',
            value: '${widget.requiredQty.toStringAsFixed(2)} IG',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleArrival(BuildContext context) async {
    if (_isNavigating) return;

    if (!_isLocationReady) {
      await _setupTripWithLocation();
      return;
    }

    debugPrint('🎯 Handle Arrival called');
    debugPrint('Stop Vehicles: ${widget.stopVehicles}');
    debugPrint('Stop Vehicles Length: ${widget.stopVehicles?.length ?? 0}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 12),
                Text('Confirm Arrival'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Have you arrived at the customer location?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Customer: ${widget.customerName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.stopVehicles != null &&
                          widget.stopVehicles!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Vehicles to service: ${widget.stopVehicles!.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Bulk delivery (no specific vehicles)',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Yes, Arrived'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final controller = context.read<TripTrackingController>();
      await controller.logManualTripEvent(
        eventType: 'arrived_at_stop',
        description: 'Driver confirmed arrival at ${widget.customerName}',
      );
      debugPrint('✅ Logged: arrived_at_stop');
    } catch (e) {
      debugPrint('❌ Error logging arrival: $e');
    }

    if (widget.stopVehicles == null || widget.stopVehicles!.isEmpty) {
      debugPrint(
        '⚠️ Bulk delivery detected (no stop_vehicles) - showing start delivery dialog',
      );
      await _showStartDeliveryDialog();
    } else {
      debugPrint('✅ Vehicles found - navigating to vehicle list');
      await _navigateToAllVehiclesScreen();
    }
  }

  Future<void> _showStartDeliveryDialog() async {
    if (!mounted) return;

    final startDelivery = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.orange),
                SizedBox(width: 12),
                Text('Start Delivery'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Do you want to start the fuel delivery now?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Customer: ${widget.customerName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_gas_station,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Quantity: ${widget.requiredQty.toStringAsFixed(2)} IG',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Start Delivery'),
              ),
            ],
          ),
    );

    if (startDelivery == true && mounted) {
      debugPrint('✅ Starting fuel delivery');
      await _navigateToFuelDeliveryScreen();
    } else {
      debugPrint('⚠️ Delivery cancelled by user');
    }
  }

  Future<void> _navigateToFuelDeliveryScreen() async {
    final stopOrder = int.tryParse(widget.stopOrder) ?? 1;
    final currentStopIndex = stopOrder - 1;

    debugPrint('========================================');
    debugPrint('📤 NAVIGATING TO FUEL DELIVERY');
    debugPrint('========================================');
    debugPrint('Stop Order: ${widget.stopOrder}');
    debugPrint('Current Stop Index: $currentStopIndex');
    debugPrint('Total Stops: ${widget.totalStops}');
    debugPrint('Is Bulk Delivery: true');
    debugPrint('========================================');

    final result = await NavigationService().pushNavigation(
      Screenroutes.customerFuelDeliveryScreen,
      arguments: {
        'assignmentId': widget.assignmentId,
        'vehicleId': widget.vehicleId,
        'tripId': widget.tripId.toString(),
        'tripStopId': widget.tripStopId ?? 0,
        'requiredQty': widget.requiredQty,
        'availableQty': widget.availableQty,
        'vehicleName': widget.vehicleName,
        'customerName': widget.customerName,
        'stopOrder': widget.stopOrder,
        'currentStopIndex': currentStopIndex,
        'totalStops': widget.totalStops,
        'driverId': widget.driverId,
        'stopVehicles': widget.stopVehicles,
        'stopVehicleId': 0,
        'isBulkDelivery': true,
      },
    );

    if (result == true && mounted) {
      debugPrint(
        '✅ Fuel delivery completed - returning to accepted assignments',
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _navigateToAllVehiclesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllVehiclesScreen(
              stopVehicles:
                  widget.stopVehicles
                      ?.map((v) => Map<String, dynamic>.from(v as Map))
                      .toList() ??
                  [],
              customerName: widget.customerName,
              siteName: widget.siteName ?? widget.customerName,
              assignment: {
                'assignment_id': widget.assignmentId,
                'trip_id': widget.tripId,
                'available_qty': widget.availableQty,
                'driver_id': widget.driverId,
                'vehicle_id': widget.vehicleId,
              },
              stop: {
                'stop_id': widget.tripStopId,
                'expected_qty': widget.requiredQty,
                'stop_order': widget.stopOrder,
              },
              totalStops: widget.totalStops,
            ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
