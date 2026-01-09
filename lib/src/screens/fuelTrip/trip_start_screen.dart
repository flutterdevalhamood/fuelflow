import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

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

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _truckAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    print('vehicleidddddd  ${widget.vehicleId}');

    // Start location check and trip setup
    _setupTripWithLocation();
  }

  Future<void> _setupTripWithLocation() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      // Step 1: Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _showLocationRequiredDialog();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          _startLocationMonitoring();
          return;
        }
      }

      // Step 2: Check and request location permission
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionSettingsDialog();
        _startLocationMonitoring();
        return;
      }

      // Step 3: For Android 10+, request background location permission
      if (permission == LocationPermission.whileInUse) {
        // Try to upgrade to "always" permission for background tracking
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

      // Step 4: Start trip tracking
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
    // Check if we're on Android 10+ where background permission is separate
    // This is a simplified check - you might want to use platform channel for accurate version
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
    // Check location every 3 seconds
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
      // Re-throw to handle in calling function
      rethrow;
    }
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Stop tracking when leaving screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final controller = context.read<TripTrackingController>();
        controller.stopTripTracking();
      } catch (e) {
        print('Error stopping trip tracking: $e');
      }
    });
    super.dispose();
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
                // Header
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
                      // Location status indicator
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

                // Main Content
                Expanded(
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

                // Trip Details Card (only shown when location is ready)
                if (_isLocationReady) _buildTripDetailsCard(),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Mark Arrival Button
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

                      // Location Help Button (when location not ready)
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
        // Animated Truck
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

        // Status indicator
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
            'Destination',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 24),
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
            value: widget.arrivalTime,
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
    // Prevent multiple navigations
    if (_isNavigating) return;

    // Double-check location is still active
    if (!_isLocationReady) {
      await _setupTripWithLocation();
      return;
    }

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
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You will proceed to fuel delivery',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
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

    // Show delivery confirmation dialog with loading state
    await _showDeliveryConfirmationDialog(context);
  }

  Future<void> _showDeliveryConfirmationDialog(BuildContext context) async {
    // Reset navigation state
    bool dialogProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return PopScope(
                canPop: !dialogProcessing,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Start Refueling'),
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
                      if (dialogProcessing) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Starting delivery...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (!dialogProcessing)
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    if (!dialogProcessing)
                      ElevatedButton(
                        onPressed: () async {
                          // Show loading state
                          setDialogState(() {
                            dialogProcessing = true;
                          });

                          setState(() {
                            _isNavigating = true;
                          });

                          try {
                            final controller =
                                context.read<TripTrackingController>();

                            // Log arrival event
                            await controller.logManualTripEvent(
                              eventType: 'arrived_at_stop',
                              description:
                                  'Driver confirmed arrival at ${widget.customerName}',
                            );

                            debugPrint('✅ Logged: arrived_at_stop');
                          } catch (e) {
                            debugPrint('❌ Error logging arrival: $e');
                            // Continue navigation even if logging fails
                          }

                          // Close dialog and navigate
                          if (mounted && Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();

                            // Small delay to ensure dialog is closed
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );

                            if (mounted) {
                              _navigateToDeliveryScreen();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Start Delivery'),
                      ),
                  ],
                ),
              );
            },
          ),
    );

    // Reset navigation state when dialog is dismissed
    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  void _navigateToDeliveryScreen() {
    NavigationService().pushReplaceNavigation(
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
        'currentStopIndex': widget.currentStopIndex,
        'totalStops': widget.totalStops,
      },
    );
  }
}

//   Future<void> _handleArrival(BuildContext context) async {
//     // Double-check location is still active
//     if (!_isLocationReady) {
//       await _setupTripWithLocation();
//       return;
//     }
//
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Row(
//               children: [
//                 Icon(Icons.location_on, color: Colors.green),
//                 SizedBox(width: 12),
//                 Text('Confirm Arrival'),
//               ],
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Have you arrived at the customer location?',
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 const SizedBox(height: 16),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.blue),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'You will proceed to fuel delivery',
//                           style: TextStyle(fontSize: 14),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text('Not Yet'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 child: const Text('Yes, Arrived'),
//               ),
//             ],
//           ),
//     );
//
//     if (confirmed == true && context.mounted) {
//       // Show second confirmation dialog for starting delivery
//       final startDelivery = await showDialog<bool>(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               title: const Row(
//                 children: [
//                   Icon(Icons.local_shipping, color: Colors.orange),
//                   SizedBox(width: 12),
//                   Text('Start Delivery'),
//                 ],
//               ),
//               content: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Do you want to start the fuel delivery now?',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                   child: const Text('Start Delivery'),
//                 ),
//               ],
//             ),
//       );
//
//       if (startDelivery == true && context.mounted) {
//         final controller = context.read<TripTrackingController>();
//
//         // Log arrival event
//         await controller.logManualTripEvent(
//           eventType: 'arrived_at_stop',
//           description: 'Driver confirmed arrival at ${widget.customerName}',
//         );
//
//         // // Refresh assignment data
//         // await context.read<FuelTripController>().getAcceptedAssignments();
//
//         if (context.mounted) {
//           // Navigate to customer fuel delivery screen
//           NavigationService().pushReplaceNavigation(
//             Screenroutes.customerFuelDeliveryScreen,
//             arguments: {
//               'assignmentId': widget.assignmentId,
//               'vehicleId': widget.vehicleId,
//               'tripId': widget.tripId.toString(),
//               'tripStopId': widget.tripStopId ?? 0,
//               'requiredQty': widget.requiredQty,
//               'availableQty': widget.availableQty,
//               'vehicleName': widget.vehicleName,
//               'customerName': widget.customerName,
//               'stopOrder': widget.stopOrder,
//               'currentStopIndex': widget.currentStopIndex,
//               'totalStops': widget.totalStops,
//             },
//           );
//         }
//       }
//     }
//   }
// }
