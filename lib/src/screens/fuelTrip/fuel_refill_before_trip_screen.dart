import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
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

  int _currentStep = 0;
  int? _stockEventId;

  @override
  void initState() {
    super.initState();
    // Pre-fill the refill quantity with the deficit
    final deficit = widget.requiredQty - widget.availableQty;
    _refillQuantityController.text = deficit.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _refillQuantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          onImagePicked(File(image.path));
        });
      }
    } catch (e) {
      // Fallback if camera/gallery not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker not available in simulator'),
        ),
      );
    }
  }

  // Future<void> _pickImage(bool isStartMeter) async {
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 80,
  //     );
  //
  //     if (image != null) {
  //       setState(() {
  //         if (isStartMeter) {
  //           _startMeterPhoto = File(image.path);
  //         } else {
  //           _endMeterPhoto = File(image.path);
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
  //   }
  // }

  Future<void> _submitFuelRefill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<FuelRefillBeforeTripControllerController>();
    final refillQty = double.tryParse(_refillQuantityController.text) ?? 0.0;
    final afterQuantity = widget.availableQty + refillQty;

    final success = await controller.postFuelVehicleRefill(
      vehicleId: widget.vehicleId,
      tripId: widget.tripId,
      tripStopId: widget.tripStopId,
      type: 'inflow',
      quantity: refillQty,
      beforeQuantity: widget.availableQty,
      afterQuantity: afterQuantity,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (success && mounted) {
      setState(() {
        _stockEventId = controller.lastStockEventId;
        _currentStep = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuel refill recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to record fuel refill',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitMeterReadings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startMeterPhoto == null || _endMeterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture both meter reading photos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_stockEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock event ID not found. Please retry fuel refill.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = context.read<FuelRefillBeforeTripControllerController>();
    final startReading = double.tryParse(_startMeterController.text) ?? 0.0;
    final endReading = double.tryParse(_endMeterController.text) ?? 0.0;

    // Submit start meter reading
    final startSuccess = await controller.postStoreMeterReadingEvent(
      stockEventId: _stockEventId,
      readingType: 'vehicle_tank_start',
      tripStopId: widget.tripStopId,
      vehicleId: widget.vehicleId,
      readingValue: double.parse(startReading.toStringAsFixed(2)),
      note: 'Depot refill start',
      photoFiles: [_startMeterPhoto!],
    );

    if (!startSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Failed to submit start meter reading',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Submit end meter reading
    final endSuccess = await controller.postStoreMeterReadingEvent(
      stockEventId: _stockEventId,
      readingType: 'vehicle_tank_end',
      tripStopId: widget.tripStopId,
      vehicleId: widget.vehicleId,
      readingValue: double.parse(endReading.toStringAsFixed(2)),
      note: 'Depot refill end',
      photoFiles: [_endMeterPhoto!],
    );

    if (endSuccess && mounted) {
      // Refresh accepted assignments to get updated fuel quantities
      await context.read<FuelTripController>().getAcceptedAssignments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refill process completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      NavigationService().navigateToUntil(
        Screenroutes.acceptedAssignmentScreen,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to submit end meter reading',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Refill'), elevation: 0),
      body: Consumer<FuelRefillBeforeTripControllerController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
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

                // Stepper
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, 'Refill', Icons.local_gas_station),
                      Expanded(
                        child: Container(
                          height: 2,
                          color:
                              _currentStep > 0
                                  ? Colors.green
                                  : Colors.grey.shade300,
                        ),
                      ),
                      _buildStepIndicator(1, 'Meter', Icons.speed),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child:
                        _currentStep == 0
                            ? _buildRefillStep()
                            : _buildMeterReadingStep(),
                  ),
                ),

                // Action Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.isSubmittingRefill ||
                                  controller.isSubmittingMeterReading
                              ? null
                              : () {
                                if (_currentStep == 0) {
                                  _submitFuelRefill();
                                } else {
                                  _submitMeterReadings();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentStep == 0 ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          controller.isSubmittingRefill ||
                                  controller.isSubmittingMeterReading
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
                                _currentStep == 0
                                    ? 'Submit Refill'
                                    : 'Complete Refill',
                                style: const TextStyle(
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
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRefillStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Required Quantity',
                  '${widget.requiredQty.toStringAsFixed(2)} L',
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Available Quantity',
                  '${widget.availableQty.toStringAsFixed(2)} L',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Deficit',
                  '${(widget.requiredQty - widget.availableQty).toStringAsFixed(2)} L',
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Refill Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _refillQuantityController,
          decoration: InputDecoration(
            labelText: 'Refill Quantity (L)',
            prefixIcon: const Icon(Icons.local_gas_station),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        const SizedBox(height: 16),
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'Note (Optional)',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildMeterReadingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meter Readings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
                  'Start Meter Reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startMeterController,
                  decoration: InputDecoration(
                    labelText: 'Reading Value',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start meter reading';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoSection(
                  'Start Meter Photo',
                  _startMeterPhoto,

                  () => _pickImage((file) => _startMeterPhoto = file),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                  'End Meter Reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endMeterController,
                  decoration: InputDecoration(
                    labelText: 'Reading Value',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end meter reading';
                    }
                    final endValue = double.tryParse(value);
                    final startValue = double.tryParse(
                      _startMeterController.text,
                    );
                    if (endValue != null &&
                        startValue != null &&
                        endValue <= startValue) {
                      return 'End reading must be greater than start reading';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoSection(
                  'End Meter Photo',
                  _endMeterPhoto,
                  () => _pickImage((file) => _endMeterPhoto = file),
                ),
              ],
            ),
          ),
        ),
      ],
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
