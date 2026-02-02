import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/util/app_routes.dart';

class TripReturnScreen extends StatefulWidget {
  final int tripId;
  final int assignmentId;
  final int vehicleId;
  final int driverId;
  final String customerName;
  final int completedCount;
  final int unavailableCount;
  final bool isDueToFuelDeficiency;
  final bool isLastStop;

  const TripReturnScreen({
    super.key,
    required this.tripId,
    required this.assignmentId,
    required this.vehicleId,
    required this.driverId,
    required this.customerName,
    required this.completedCount,
    required this.unavailableCount,
    this.isDueToFuelDeficiency = false,
    this.isLastStop = true,
  });

  @override
  State<TripReturnScreen> createState() => _TripReturnScreenState();
}

class _TripReturnScreenState extends State<TripReturnScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _truckAnimation;
  bool _isLocationReady = false;
  bool _isCheckingLocation = false;
  bool _hasShownLocationDialog = false;
  bool _isProcessing = false;

  bool _movingTowardsBaseLogged = false;

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

        await _logMovingTowardsBase();
      } else {
        await _setupReturnWithLocation();
      }
    } else {
      await _setupReturnWithLocation();
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

  Future<void> _logMovingTowardsBase() async {
    if (_movingTowardsBaseLogged) return;

    try {
      final controller = context.read<TripTrackingController>();

      // ADD THIS: Use different event type based on fuel deficiency
      final eventType =
          widget.isDueToFuelDeficiency
              ? 'moving_towards_base_due_to_fuel_deficiency'
              : 'moving_towards_base';

      final success = await controller.logManualTripEvent(
        eventType: eventType, // CHANGED: Use dynamic event type
        description:
            'Moving towards base from ${widget.customerName} (${widget.completedCount} completed, ${widget.unavailableCount} unavailable)',
      );

      if (success) {
        _movingTowardsBaseLogged = true;
        debugPrint('✅ Logged: $eventType'); // CHANGED: Log dynamic event type
      } else {
        debugPrint(
          '⚠️ Failed to log $eventType',
        ); // CHANGED: Log dynamic event type
      }
    } catch (e) {
      debugPrint('❌ Error logging moving_towards_base: $e');
    }
  }

  Future<void> _setupReturnWithLocation() async {
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

      await _startReturnTracking();

      setState(() {
        _isLocationReady = true;
        _isCheckingLocation = false;
      });

      _animationController.repeat(reverse: true);
    } catch (e) {
      debugPrint('❌ Error setting up return tracking: $e');
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
              'To track your return journey accurately, please allow location access "All the time" in the next screen.',
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
                  'To track your return journey to base, please enable location services.',
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
                child: const Text('Cancel'),
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
                  'Please grant location permission to track your return journey.',
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
                child: const Text('Cancel'),
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
            await _startReturnTracking();
            setState(() {
              _isLocationReady = true;
              _isCheckingLocation = false;
            });
            _animationController.repeat(reverse: true);
          }
        }
      } catch (e) {
        debugPrint('❌ Location monitoring error: $e');
      }
    });
  }

  Future<void> _startReturnTracking() async {
    try {
      final controller = context.read<TripTrackingController>();

      // ADD THIS: Use different event type based on fuel deficiency
      final eventType =
          widget.isDueToFuelDeficiency
              ? 'moving_towards_base_due_to_fuel_deficiency'
              : 'moving_towards_base';

      if (!controller.isTracking) {
        await controller.startTripTracking(
          tripId: widget.tripId,
          tripStopId: null,
          eventType: eventType, // CHANGED: Use dynamic event type
          driverId: widget.driverId,
          vehicleId: widget.vehicleId,
        );
      }

      await _logMovingTowardsBase();

      debugPrint('✅ Return tracking started for trip ${widget.tripId}');
    } catch (e) {
      debugPrint('❌ Error starting return tracking: $e');
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
    super.dispose();
  }

  Future<void> _handleReachedBase() async {
    if (_isProcessing) return;

    if (!_isLocationReady) {
      await _setupReturnWithLocation();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.home, color: Colors.green),
                const SizedBox(width: 12),
                // UPDATED: Change title based on isLastStop
                Text('Confirm Arrival at Base'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UPDATED: Change question based on isLastStop
                Text(
                  widget.isLastStop
                      ? 'Have you arrived at the base?'
                      : 'Have you arrived at the base to refuel?',
                  style: const TextStyle(fontSize: 16),
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
                          const Expanded(
                            child: Text(
                              'Trip Summary',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completed: ${widget.completedCount}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Unavailable: ${widget.unavailableCount}',
                        style: const TextStyle(fontSize: 14),
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

    setState(() => _isProcessing = true);

    try {
      final controller = context.read<TripTrackingController>();

      // UPDATED: Fire different events based on isLastStop
      String eventType;
      String description;

      if (widget.isLastStop) {
        eventType = 'returned_to_base';
        description =
            'Returned to base from ${widget.customerName} (${widget.completedCount} completed, ${widget.unavailableCount} unavailable)';
      } else {
        eventType = 'reached_base_for_refuel';
        description =
            'Reached base for refuel from ${widget.customerName} (${widget.completedCount} completed, ${widget.unavailableCount} unavailable)';
      }

      final success = await controller.logManualTripEvent(
        eventType: eventType,
        description: description,
      );

      if (!success) {
        debugPrint('⚠️ Failed to log $eventType event');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Failed to log $eventType event'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('✅ Logged: $eventType');
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Screenroutes.acceptedAssignmentScreen,
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isLastStop
                  ? 'Successfully returned to base'
                  : 'Successfully reached base for refuel',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error logging return to base: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Cancel Return Journey?'),
                content: const Text(
                  'Are you sure you want to cancel the return journey to base?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continue Journey'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
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
              colors: [Colors.green.shade400, Colors.green.shade700],
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
                                  title: const Text('Cancel Return Journey?'),
                                  content: const Text(
                                    'Are you sure you want to cancel the return journey to base?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Continue Journey'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Cancel'),
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
                            Text(
                              widget.isDueToFuelDeficiency
                                  ? 'Returning to Base - Fuel Depleted' // ADD THIS
                                  : 'Returning to Base',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.isDueToFuelDeficiency
                                  ? 'Refuel required to continue' // ADD THIS
                                  : 'Trip in progress',
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCheckingLocation)
                          _buildCheckingLocationContent()
                        else if (!_isLocationReady)
                          _buildLocationRequiredContent()
                        else
                          _buildReturnActiveContent(),
                      ],
                    ),
                  ),
                ),

                if (_isLocationReady) _buildTripSummaryCard(),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLocationReady && !_isProcessing
                                  ? _handleReachedBase
                                  : null,
                          icon:
                              _isProcessing
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.check_circle),
                          label:
                              _isProcessing
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    widget.isLastStop
                                        ? 'Reached Base'
                                        : 'Reached Base for Refuel', // UPDATED
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isLocationReady && !_isProcessing
                                    ? Colors.green
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isLocationReady)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _setupReturnWithLocation,
                            icon: const Icon(Icons.location_on),
                            label: const Text('Enable Location to Continue'),
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
          'Setting Up Return Journey',
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
            'Please enable location services to track your return journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _setupReturnWithLocation,
          icon: const Icon(Icons.location_on),
          label: const Text('Enable Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnActiveContent() {
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
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
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
                'Returning to Base',
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

  Widget _buildTripSummaryCard() {
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
            'Trip Summary',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.home, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isLastStop
                      ? 'Returning to Base'
                      : 'Returning to Base for Refuel', // UPDATED
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
            icon: Icons.check_circle,
            label: 'Completed Deliveries',
            value: widget.completedCount.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.block,
            label: 'Unavailable Vehicles',
            value: widget.unavailableCount.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
