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

class FuelRefillBeforeTripScreen extends StatefulWidget {
  final int assignmentId;
  final int vehicleId;
  final String tripId;
  final int tripStopId;
  final double requiredQty;
  final double availableQty;
  final String vehicleName;
  final String stopOrder;
  final String customerName;

  const FuelRefillBeforeTripScreen({
    Key? key,
    required this.assignmentId,
    required this.vehicleId,
    required this.tripId,
    required this.tripStopId,
    required this.requiredQty,
    required this.availableQty,
    required this.vehicleName,
    this.stopOrder = '1',
    this.customerName = '',
  }) : super(key: key);

  @override
  State<FuelRefillBeforeTripScreen> createState() =>
      _FuelRefillBeforeTripScreenState();
}

class _FuelRefillBeforeTripScreenState
    extends State<FuelRefillBeforeTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _startMeterController = TextEditingController();
  final _endMeterController = TextEditingController();
  final _refillQuantityController = TextEditingController();
  final _noteController = TextEditingController();

  File? _startMeterPhoto;
  File? _endMeterPhoto;

  final ImagePicker _picker = ImagePicker();

  // ✅ Cached providers (NO context usage later)
  late TripTrackingController _trackingController;
  late FuelTripController _fuelTripController;
  late FuelRefillBeforeTripControllerController _refillController;

  // ✅ Add scaffold messenger key to show messages safely
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Pre-fill the refill quantity with the deficit
    final deficit = widget.requiredQty - widget.availableQty;
    _refillQuantityController.text = deficit.toStringAsFixed(2);

    // ✅ Cache all providers in initState
    _trackingController = context.read<TripTrackingController>();
    _fuelTripController = context.read<FuelTripController>();
    _refillController =
        context.read<FuelRefillBeforeTripControllerController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _logTripEvent('arrived_at_depot');
      }
    });
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _refillQuantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // =================== SAFE EVENT LOGGING ===================

  Future<void> _logTripEvent(String eventType, {String? description}) async {
    if (!mounted) return;

    try {
      await _trackingController.logManualTripEvent(
        eventType: eventType,
        description: description ?? 'Event: $eventType at depot',
      );
    } catch (e) {
      debugPrint('❌ Trip event error [$eventType]: $e');
    }
  }

  // =================== SAFE SNACKBAR ===================

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // =================== IMAGE PICKER ===================

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

  // =================== SUBMIT REFILL ===================

  Future<void> _submitFuelRefill() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    if (_startMeterPhoto == null || _endMeterPhoto == null) {
      _showSnackBar(
        'Please capture both meter reading photos',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final refillQty = double.tryParse(_refillQuantityController.text) ?? 0;
    final afterQuantity = widget.availableQty + refillQty;

    // ✅ Log refuel started
    await _logTripEvent('refuel_started', description: 'Started depot refill');

    if (!mounted) return;

    // ✅ Use cached controller
    final success = await _refillController.postFuelVehicleWithMeterReading(
      vehicleId: widget.vehicleId,
      tripId: widget.tripId,
      tripStopId: widget.tripStopId,
      type: 'inflow',
      quantity: refillQty,
      beforeQuantity: widget.availableQty,
      afterQuantity: afterQuantity,
      customerStartMeterReadingValue: 0,
      customerStartMeterFiles: const [],
      customerEndMeterReadingValue: 0,
      customerEndMeterFiles: const [],
      vehicleTankStartReadingValue:
          int.tryParse(_startMeterController.text) ?? 0,
      vehicleStartMeterFiles: [_startMeterPhoto!],
      vehicleTankEndReadingValue: int.tryParse(_endMeterController.text) ?? 0,
      vehicleEndMeterFiles: [_endMeterPhoto!],
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (!mounted) return;

    if (success) {
      // ✅ Log refuel_completed IMMEDIATELY after success
      await _logTripEvent(
        'refuel_completed',
        description: 'Refilled ${_refillQuantityController.text} IG at depot',
      );
      debugPrint('✅ refuel_completed logged immediately after refill success');

      // ✅ REMOVED: getAcceptedAssignments call that was causing crashes
      // The data will be refreshed when navigating back to the assignments screen

      if (!mounted) return;

      _showSnackBar(
        'Refill completed successfully',
        backgroundColor: Colors.green,
      );

      // ✅ Log remaining events in background (fire and forget)
      _logRemainingEventsInBackground();

      // ✅ Show dialog immediately
      if (mounted) {
        _showCompletionDialog();
      }
    } else {
      _showSnackBar(
        _refillController.errorMessage ?? 'Failed to complete refill',
        backgroundColor: Colors.red,
      );
    }
  }

  // ✅ Fire-and-forget background logging (no await)
  void _logRemainingEventsInBackground() {
    // Don't await - let it run in background
    Future.microtask(() async {
      try {
        if (_noteController.text.isNotEmpty) {
          await _trackingController.logManualTripEvent(
            eventType: 'driver_notes_added',
            description: _noteController.text,
          );
        }

        await _trackingController.logManualTripEvent(
          eventType: 'departed_from_depot',
          description: 'Departed from depot after refill',
        );

        debugPrint('✅ Background events logged successfully');
      } catch (e) {
        debugPrint('❌ Remaining events logging failed: $e');
      }
    });
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('Refill Completed'),
              content: const Text(
                'Depot refill completed successfully. Return to assignments?',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // 1️⃣ Close dialog using root navigator
                    Navigator.of(dialogContext, rootNavigator: true).pop();

                    // 2️⃣ Wait for dialog pop to complete
                    await Future.microtask(() {});

                    // 3️⃣ Ensure widget is still alive
                    if (!mounted) return;

                    // 4️⃣ Navigate safely
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
                title: const Text('Cancel Refill?'),
                content: const Text(
                  'You have already arrived at depot and started refill. '
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
          appBar: AppBar(title: const Text('Fuel Refill'), elevation: 0),
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
                          colors: [Colors.orange, Colors.orange.shade300],
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
                                  Icons.local_gas_station,
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
                                      'Depot Refill',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Vehicle: ${widget.vehicleName}',
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
                                      Colors.red,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Available in Vehicle',
                                      '${widget.availableQty.toStringAsFixed(2)} IG',
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Deficit',
                                      '${(widget.requiredQty - widget.availableQty).toStringAsFixed(2)} IG',
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Refill Quantity
                            const Text(
                              'Refill Quantity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _refillQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity (IG)',
                                prefixIcon: const Icon(Icons.local_gas_station),
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
                                  return 'Please enter refill quantity';
                                }
                                final qty = double.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Vehicle Tank Meter Readings
                            const Text(
                              'Vehicle Tank Meter Readings',
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
                                      'Start Meter Reading Serial Number',
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
                                      'End Meter Reading Serial Number',
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
                                  : _submitFuelRefill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
                                    'Complete Refill',
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
