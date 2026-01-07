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
  late FuelRefillBeforeTripController _refillController;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _deliveryQuantityController.text = widget.requiredQty.toStringAsFixed(2);

    _trackingController = context.read<TripTrackingController>();
    _fuelTripController = context.read<FuelTripController>();
    _refillController = context.read<FuelRefillBeforeTripController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  Future<void> _initializeTracking() async {
    if (!mounted) return;

    try {
      await _trackingController.startTripTracking(
        tripId: int.parse(widget.tripId),
        tripStopId: widget.tripStopId,
        eventType: 'arrived_at_stop',
      );
    } catch (e) {
      debugPrint('Tracking init failed: $e');
    }
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _deliveryQuantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _pickImage(Function(File) onPicked) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => onPicked(File(image.path)));
      }
    } catch (e) {
      _showSnackBar('Image pick failed');
    }
  }

  Future<void> _submitFuelDelivery() async {
    if (!mounted || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_startMeterPhoto == null || _endMeterPhoto == null) {
      _showSnackBar('Please capture both meter photos');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _trackingController.logManualTripEvent(eventType: 'refuel_started');

      await Future.delayed(const Duration(milliseconds: 300));

      final success = await _refillController.postFuelVehicleWithMeterReading(
        vehicleId: widget.vehicleId,
        tripId: widget.tripId,
        tripStopId: widget.tripStopId,
        type: 'outflow',
        quantity: double.parse(_deliveryQuantityController.text),
        beforeQuantity: widget.availableQty,
        afterQuantity:
            widget.availableQty -
            double.parse(_deliveryQuantityController.text),
        customerStartMeterReadingValue:
            int.tryParse(_startMeterController.text) ?? 0,
        customerStartMeterFiles: [
          _startMeterPhoto!,
        ], // ✅ These are now being passed
        customerEndMeterReadingValue:
            int.tryParse(_endMeterController.text) ?? 0,
        customerEndMeterFiles: [
          _endMeterPhoto!,
        ], // ✅ These are now being passed
        note: _noteController.text,
        vehicleTankStartReadingValue: 0,
        vehicleStartMeterFiles: const [], // ✅ Empty for customer delivery
        vehicleTankEndReadingValue: 0,
        vehicleEndMeterFiles: const [], // ✅ Empty for customer delivery
      );

      if (!success || !mounted) {
        _showSnackBar('Delivery failed', backgroundColor: Colors.red);
        return;
      }

      await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_completed',
      );

      await _logAdditionalEvents();

      final isLastStop = widget.currentStopIndex >= widget.totalStops - 1;

      if (isLastStop) {
        await _trackingController.logCriticalTripEvent(
          eventType: 'returned_to_base',
        );
        await _trackingController.stopTripTracking();
      }

      _showCompletionDialog();
    } catch (e) {
      _showSnackBar('Error occurred', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logAdditionalEvents() async {
    if (!_trackingController.isTracking) return;

    try {
      await _trackingController.logManualTripEvent(
        eventType: 'customer_loading_started',
      );
      await _trackingController.logManualTripEvent(
        eventType: 'customer_loading_completed',
      );
      if (_noteController.text.isNotEmpty) {
        await _trackingController.logManualTripEvent(
          eventType: 'driver_notes_added',
        );
      }
      await _trackingController.logManualTripEvent(
        eventType: 'departed_from_stop',
      );
    } catch (_) {}
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Stop Completed'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  NavigationService().navigateToUntil(
                    Screenroutes.acceptedAssignmentScreen,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSubmitting) return false;

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
          body: Consumer<FuelRefillBeforeTripController>(
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
                          onPressed: _isSubmitting ? null : _submitFuelDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isSubmitting
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
