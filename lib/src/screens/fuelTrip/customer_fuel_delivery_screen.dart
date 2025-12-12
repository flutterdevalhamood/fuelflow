import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
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

  int _currentStep = 0;
  int? _stockEventId;

  @override
  void initState() {
    super.initState();
    // Pre-fill the delivery quantity with required quantity
    _deliveryQuantityController.text = widget.requiredQty.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _deliveryQuantityController.dispose();
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

  // Future<void> _pickImage(Function(File) onImagePicked) async {
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 80,
  //     );
  //     if (image != null) {
  //       setState(() {
  //         onImagePicked(File(image.path));
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to capture image: $e'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //   }
  // }

  Future<void> _submitFuelDelivery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<FuelRefillBeforeTripControllerController>();
    final deliveryQty =
        double.tryParse(_deliveryQuantityController.text) ?? 0.0;
    final afterQuantity = widget.availableQty - deliveryQty;

    if (deliveryQty > widget.availableQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery quantity cannot exceed available quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await controller.postFuelVehicleRefill(
      vehicleId: widget.vehicleId,
      tripId: widget.tripId,
      tripStopId: widget.tripStopId,
      type: 'outflow', // Fuel going OUT to customer
      quantity: deliveryQty,
      beforeQuantity: widget.availableQty,
      afterQuantity: afterQuantity,
      note:
          _noteController.text.isEmpty
              ? 'Fuel delivery to ${widget.customerName}'
              : _noteController.text,
    );

    if (success && mounted) {
      setState(() {
        _stockEventId = controller.lastStockEventId;
        _currentStep = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuel delivery recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to record fuel delivery',
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
          content: Text(
            'Stock event ID not found. Please retry fuel delivery.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = context.read<FuelRefillBeforeTripControllerController>();
    final startReading = double.tryParse(_startMeterController.text) ?? 0.0;
    final endReading = double.tryParse(_endMeterController.text) ?? 0.0;

    // Submit start meter reading for customer
    final startSuccess = await controller.postStoreMeterReadingEvent(
      stockEventId: _stockEventId,
      readingType: 'customer_start_meter',
      tripStopId: widget.tripStopId,
      vehicleId: widget.vehicleId,
      readingValue: double.parse(startReading.toStringAsFixed(2)),
      note: 'Customer delivery start - ${widget.customerName}',
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

    // Submit end meter reading for customer
    final endSuccess = await controller.postStoreMeterReadingEvent(
      stockEventId: _stockEventId,
      readingType: 'customer_end_meter',
      tripStopId: widget.tripStopId,
      vehicleId: widget.vehicleId,
      readingValue: double.parse(endReading.toStringAsFixed(2)),
      note: 'Customer delivery end - ${widget.customerName}',
      photoFiles: [_endMeterPhoto!],
    );

    if (endSuccess && mounted) {
      // Refresh accepted assignments to get updated fuel quantities
      await context.read<FuelTripController>().getAcceptedAssignments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Show dialog for next action
      _showCompletionDialog();
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

  void _showCompletionDialog() {
    final isLastStop = widget.currentStopIndex >= widget.totalStops - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Stop Completed')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Delivered to ${widget.customerName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stop:'),
                          Text(
                            '${widget.currentStopIndex + 1} of ${widget.totalStops}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isLastStop
                      ? 'All stops completed! Return to depot?'
                      : 'Ready to proceed to the next stop?',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              if (isLastStop)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    NavigationService().navigateToUntil(
                      Screenroutes.acceptedAssignmentScreen,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Return to Depot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    NavigationService().navigateToUntil(
                      Screenroutes.acceptedAssignmentScreen,
                    );
                  },
                  child: const Text('View All Stops'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    NavigationService().navigateToUntil(
                      Screenroutes.acceptedAssignmentScreen,
                    );
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Next Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Fuel Delivery'), elevation: 0),
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

                // Stepper
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, 'Delivery', Icons.local_shipping),
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
                            ? _buildDeliveryStep()
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
                                  _submitFuelDelivery();
                                } else {
                                  _submitMeterReadings();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentStep == 0 ? Colors.blue : Colors.green,
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
                                    ? 'Submit Delivery'
                                    : 'Complete Delivery',
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

  Widget _buildDeliveryStep() {
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
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Available in Vehicle',
                  '${widget.availableQty.toStringAsFixed(2)} L',
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Delivery Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _deliveryQuantityController,
          decoration: InputDecoration(
            labelText: 'Delivery Quantity (L)',
            prefixIcon: const Icon(Icons.local_shipping),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          'Customer Meter Readings',
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
