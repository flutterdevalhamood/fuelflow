import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class CustomerFuelDeliveryScreen extends StatefulWidget {
  final int assignmentId;
  final int vehicleId;
  final String tripId;
  final int tripStopId;
  final double requiredQty;
  final double availableQty;
  final String vehicleName;
  final String customerName;
  final String stopOrder;
  final int currentStopIndex;
  final int totalStops;

  const CustomerFuelDeliveryScreen({
    Key? key,
    required this.assignmentId,
    required this.vehicleId,
    required this.tripId,
    required this.tripStopId,
    required this.requiredQty,
    required this.availableQty,
    required this.vehicleName,
    required this.customerName,
    required this.stopOrder,
    required this.currentStopIndex,
    required this.totalStops,
  }) : super(key: key);

  @override
  State<CustomerFuelDeliveryScreen> createState() =>
      _CustomerFuelDeliveryScreenState();
}

class _CustomerFuelDeliveryScreenState
    extends State<CustomerFuelDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _startMeterController = TextEditingController();
  final _endMeterController = TextEditingController();
  final _deliveryQuantityController = TextEditingController();
  final _noteController = TextEditingController();

  File? _startMeterPhoto;
  File? _endMeterPhoto;

  final ImagePicker _picker = ImagePicker();

  late TripTrackingController _trackingController;
  late FuelTripController _fuelTripController;
  late FuelRefillBeforeTripControllerController _refillController;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _refuelCompletedLogged = false;

  @override
  void initState() {
    super.initState();

    _deliveryQuantityController.text = widget.requiredQty.toStringAsFixed(2);
    _trackingController = context.read<TripTrackingController>();
    _fuelTripController = context.read<FuelTripController>();
    _refillController =
        context.read<FuelRefillBeforeTripControllerController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _trackingController.startTripTracking(
        tripId: int.parse(widget.tripId),
        tripStopId: widget.tripStopId,
        eventType: 'arrived_at_stop',
      );
    });
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _deliveryQuantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _logTripEvent(String eventType, {String? description}) async {
    if (!mounted) return;

    try {
      await _trackingController.logManualTripEvent(
        eventType: eventType,
        description:
            description ?? 'Event: $eventType at ${widget.customerName}',
      );
      debugPrint('✅ Logged event: $eventType');
    } catch (e) {
      debugPrint('❌ Trip event failed [$eventType]: $e');
    }
  }

  Future<bool> _logRefuelCompletedSafely() async {
    if (_refuelCompletedLogged) return true;

    try {
      // 🔐 Ensure trip context exists
      if (!_trackingController.isTracking) {
        await _trackingController.startTripTracking(
          tripId: int.parse(widget.tripId),
          tripStopId: widget.tripStopId,
          eventType: 'refuel_completed',
        );
      }

      final success = await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_completed',
      );

      _refuelCompletedLogged = success;
      return success;
    } catch (e) {
      debugPrint('❌ refuel_completed failed safely: $e');
      return false; // ❗ NEVER CRASH
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _pickImage(Function(File) onPicked) async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() => onPicked(File(image.path)));
      }
    } catch (_) {
      _showSnackBar('Image picker not available');
    }
  }

  Future<void> _submitFuelDelivery() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    if (_startMeterPhoto == null || _endMeterPhoto == null) {
      _showSnackBar(
        'Please capture both meter reading photos',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final deliveryQty = double.tryParse(_deliveryQuantityController.text) ?? 0;

    if (deliveryQty > widget.availableQty) {
      _showSnackBar(
        'Delivery quantity exceeds available quantity',
        backgroundColor: Colors.red,
      );
      return;
    }

    // ✅ Log refuel started
    await _logTripEvent('refuel_started');

    if (!mounted) return;

    // ✅ Use cached controller
    final success = await _refillController.postFuelVehicleWithMeterReading(
      vehicleId: widget.vehicleId,
      tripId: widget.tripId,
      tripStopId: widget.tripStopId,
      type: 'outflow',
      quantity: deliveryQty,
      beforeQuantity: widget.availableQty,
      afterQuantity: widget.availableQty - deliveryQty,
      customerStartMeterReadingValue:
          int.tryParse(_startMeterController.text) ?? 0,
      customerStartMeterFiles: [_startMeterPhoto!],
      customerEndMeterReadingValue: int.tryParse(_endMeterController.text) ?? 0,
      customerEndMeterFiles: [_endMeterPhoto!],
      note: _noteController.text,
      vehicleTankStartReadingValue: 0,
      vehicleStartMeterFiles: const [],
      vehicleTankEndReadingValue: 0,
      vehicleEndMeterFiles: const [],
    );

    if (!mounted) return;
    if (success) {
      // 🔴 CRITICAL EVENT — MUST COMPLETE FIRST
      final refuelLogged = await _logRefuelCompletedSafely();

      if (!refuelLogged && mounted) {
        _showSnackBar(
          'Delivery completed but event logging failed',
          backgroundColor: Colors.orange,
        );
      }

      // ⏳ Give network time before navigation
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      _showSnackBar(
        'Delivery completed successfully',
        backgroundColor: Colors.green,
      );

      // 🧵 Background-only logs (NON-BLOCKING)
      _logRemainingEventsInBackground();

      if (mounted) {
        _showCompletionDialog();
      }
    } else {
      _showSnackBar(
        _refillController.errorMessage ?? 'Failed to complete delivery',
        backgroundColor: Colors.red,
      );
    }
  }

  // ✅ Fire-and-forget background logging (no await)
  void _logRemainingEventsInBackground() {
    // Don't await - let it run in background
    Future.microtask(() async {
      try {
        await _trackingController.logManualTripEvent(
          eventType: 'customer_loading_started',
          description: 'Started fuel delivery to ${widget.customerName}',
        );

        if (_noteController.text.isNotEmpty) {
          await _trackingController.logManualTripEvent(
            eventType: 'driver_notes_added',
            description: _noteController.text,
          );
        }

        await _trackingController.logManualTripEvent(
          eventType: 'departed_from_stop',
          description: 'Departed from ${widget.customerName}',
        );

        debugPrint('✅ Background events logged successfully');
      } catch (e) {
        debugPrint('❌ Remaining events logging failed: $e');
      }
    });
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    final isLastStop = widget.currentStopIndex >= widget.totalStops - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('Stop Completed'),
              content: Text(
                isLastStop
                    ? 'All stops completed. Return to depot?'
                    : 'Proceed to next stop?',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // ✅ Close dialog first
                    Navigator.of(dialogContext).pop();

                    // ✅ Navigate using NavigationService
                    NavigationService().navigateToUntil(
                      Screenroutes.acceptedAssignmentScreen,
                    );
                  },
                  child: const Text('OK'),
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
                title: const Text('Cancel Delivery?'),
                content: const Text(
                  'You have already arrived and started delivery. '
                  'Are you sure you want to go back? Progress may be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stay'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
        );
        return shouldPop ?? false;
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Customer Fuel Delivery'),
            elevation: 0,
          ),
          body: Consumer<FuelRefillBeforeTripControllerController>(
            builder: (context, controller, child) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Customer Delivery',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.customerName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Stop ${widget.currentStopIndex + 1} of ${widget.totalStops}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fuel Status Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fuel Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      'Required Quantity',
                                      '${widget.requiredQty.toStringAsFixed(2)} IG',
                                      Colors.blue,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Available in Vehicle',
                                      '${widget.availableQty.toStringAsFixed(2)} IG',
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Delivery Quantity
                            const Text(
                              'Delivery Quantity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _deliveryQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity (IG)',
                                prefixIcon: const Icon(Icons.local_shipping),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter delivery quantity';
                                }
                                final qty = double.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                if (qty > widget.availableQty) {
                                  return 'Cannot exceed available quantity';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Customer Meter Readings
                            const Text(
                              'Customer Meter Readings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Start Meter
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPhotoSection(
                                      'Start Meter Photo',
                                      _startMeterPhoto,
                                      () => _pickImage(
                                        (file) => _startMeterPhoto = file,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Start Meter Reading',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _startMeterController,
                                      decoration: InputDecoration(
                                        labelText: 'Reading Value',
                                        prefixIcon: const Icon(Icons.speed),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter start meter reading';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // End Meter
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPhotoSection(
                                      'End Meter Photo',
                                      _endMeterPhoto,
                                      () => _pickImage(
                                        (file) => _endMeterPhoto = file,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'End Meter Reading',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _endMeterController,
                                      decoration: InputDecoration(
                                        labelText: 'Reading Value',
                                        prefixIcon: const Icon(Icons.speed),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter end meter reading';
                                        }
                                        final endValue = int.tryParse(value);
                                        final startValue = int.tryParse(
                                          _startMeterController.text,
                                        );
                                        if (endValue != null &&
                                            startValue != null &&
                                            endValue <= startValue) {
                                          return 'End reading must be greater than start';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Note
                            TextFormField(
                              controller: _noteController,
                              decoration: InputDecoration(
                                labelText: 'Note (Optional)',
                                prefixIcon: const Icon(Icons.note),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Submit Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              controller.isSubmittingRefill
                                  ? null
                                  : _submitFuelDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              controller.isSubmittingRefill
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
                                  : const Text(
                                    'Complete Delivery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(String label, File? photo, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child:
                photo == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to capture',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
          ),
        ),
      ],
    );
  }
}
