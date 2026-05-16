import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/util/refill_state.dart';

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
  final bool isVehicleToVehicleRefill;

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
    this.isVehicleToVehicleRefill = false,
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
  bool _isSubmitting = false;
  bool _showCompletionDialog = false;
  bool _shouldNavigateBack = false;

  final _startMeterFocusNode = FocusNode();
  final _endMeterFocusNode = FocusNode();

  // Calculate meter reading difference
  int get _meterReadingDifference {
    final startValue = int.tryParse(_startMeterController.text) ?? 0;
    final endValue = int.tryParse(_endMeterController.text) ?? 0;
    return endValue - startValue;
  }

  // Check if quantity matches meter difference
  bool get _isQuantityMismatch {
    if (_refillQuantityController.text.isEmpty) return false;
    final refillQty = double.tryParse(_refillQuantityController.text) ?? 0;
    return refillQty != _meterReadingDifference.toDouble();
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to update UI when values change
    _startMeterController.addListener(() => setState(() {}));
    _endMeterController.addListener(() => setState(() {}));
    _refillQuantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _startMeterController.dispose();
    _endMeterController.dispose();
    _refillQuantityController.dispose();
    _noteController.dispose();
    _startMeterFocusNode.dispose();
    _endMeterFocusNode.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage(
    Function(File) onImagePicked,
    FocusNode? focusNode,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        setState(() {
          onImagePicked(File(image.path));
        });

        // Auto-focus the next text field after image is selected
        if (focusNode != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              FocusScope.of(context).requestFocus(focusNode);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker not available in simulator'),
        ),
      );
    }
  }

  Future<void> _submitFuelRefill() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_startMeterPhoto == null) {
      _showSnackBar(
        'Please capture start meter photo',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_endMeterPhoto == null) {
      _showSnackBar(
        'Please capture end meter photo',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final refillQty = double.tryParse(_refillQuantityController.text) ?? 0;
    if (refillQty <= 0) {
      _showSnackBar(
        'Please enter valid refill quantity',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final startValue = int.tryParse(_startMeterController.text) ?? 0;
    final endValue = int.tryParse(_endMeterController.text) ?? 0;

    if (endValue <= startValue) {
      _showSnackBar(
        'End reading must be greater than start reading',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final trackingController = context.read<TripTrackingController>();
      final refillController = context.read<FuelRefillBeforeTripController>();

      // Log refuel started
      await trackingController.logManualTripEvent(eventType: 'refuel_started');

      // ========== LOG API REQUEST DATA ==========
      debugPrint('📤 ===== FUEL REFILL API REQUEST =====');
      debugPrint('vehicleId: ${widget.vehicleId}');
      debugPrint('tripId: ${widget.tripId}');
      debugPrint('tripStopId: ${widget.tripStopId}');
      debugPrint('type: inflow');
      debugPrint('quantity: $refillQty');
      debugPrint('beforeQuantity: ${widget.availableQty}');
      debugPrint('afterQuantity: ${widget.availableQty + refillQty}');
      debugPrint('customerStartMeterReadingValue: 0');
      debugPrint('customerEndMeterReadingValue: 0');
      debugPrint('vehicleTankStartReadingValue: $startValue');
      debugPrint('vehicleTankEndReadingValue: $endValue');
      debugPrint('startMeterPhoto path: ${_startMeterPhoto!.path}');
      debugPrint('endMeterPhoto path: ${_endMeterPhoto!.path}');
      debugPrint(
        'note: ${_noteController.text.trim().isEmpty ? 'null' : _noteController.text.trim()}',
      );
      debugPrint('📤 ====================================');

      // Submit fuel refill
      final success = await refillController.postFuelVehicleWithMeterReading(
        vehicleId: widget.vehicleId,
        tripId: widget.tripId,
        tripStopId: widget.tripStopId,
        type: 'inflow',
        quantity: refillQty,
        beforeQuantity: widget.availableQty,
        afterQuantity: widget.availableQty + refillQty,
        customerStartMeterReadingValue: 0,
        customerStartMeterFiles: const [],
        customerEndMeterReadingValue: 0,
        customerEndMeterFiles: const [],
        vehicleTankStartReadingValue: startValue,
        vehicleStartMeterFiles: [_startMeterPhoto!],
        vehicleTankEndReadingValue: endValue,
        vehicleEndMeterFiles: [_endMeterPhoto!],
        note:
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
      );

      // Log API response
      debugPrint('📥 API Response - Success: $success');

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Fuel refill completed successfully');

        // Log critical events
        await trackingController.logCriticalTripEvent(
          eventType: 'refuel_completed',
        );

        if (_noteController.text.trim().isNotEmpty) {
          await trackingController.logManualTripEvent(
            eventType: 'driver_notes_added',
          );
        }

        await trackingController.logManualTripEvent(
          eventType: 'departed_from_depot',
        );

        // Show success message
        _showSnackBar(
          'Fuel refill completed successfully!',
          backgroundColor: Colors.green,
        );

        // Wait a bit then show completion dialog
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          _showCompletionDialogSafe();
        }
      } else {
        final errorMsg =
            refillController.errorMessage ?? 'Failed to complete refill';
        debugPrint('❌ API Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Refill error: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _showSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCompletionDialogSafe() {
    if (_showCompletionDialog || !mounted) return;

    setState(() => _showCompletionDialog = true);

    // Use a delayed future to ensure dialog builds properly
    Future.delayed(Duration.zero, () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Refill Completed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_all, color: Colors.green, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Fuel refill was completed successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You can now continue with your trip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        setState(() {
                          _showCompletionDialog = false;
                          _shouldNavigateBack = true;
                        });
                        // Navigate back after dialog is dismissed
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _shouldNavigateBack) {
                            _navigateBack();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((value) {
        if (mounted) {
          setState(() => _showCompletionDialog = false);
        }
      });
    });
  }

  void _navigateBack() {
    // RESET THE FLAG when leaving the refill screen
    if (widget.isVehicleToVehicleRefill) {
      RefillState.isAwaitingAdminRefill = false;
      debugPrint('🔄 Reset admin refill flag');
    }

    // Return to previous screen with success result
    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
                title: const Text('Cancel Refill?'),
                content: const Text(
                  'Are you sure you want to cancel the fuel refill? '
                  'All entered data will be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.isVehicleToVehicleRefill) {
                        RefillState.isAwaitingAdminRefill = false;
                        debugPrint('🔄 Reset admin refill flag (cancelled)');
                      }
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Yes, Cancel'),
                  ),
                ],
              ),
        );

        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isVehicleToVehicleRefill
                ? 'Vehicle to Vehicle Refill'
                : 'Fuel Refill',
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_isSubmitting) {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Cancel Refill?'),
                        content: const Text('Are you sure you want to cancel?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                );
                if (shouldPop ?? false && mounted) {
                  Navigator.of(context).pop(false);
                }
              }
            },
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Vehicle Info Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.orange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vehicleName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trip: ${widget.tripId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fuel Summary
                      _buildFuelSummary(),
                      const SizedBox(height: 24),

                      // Meter Readings
                      _buildMeterReadings(),
                      const SizedBox(height: 24),

                      // Meter Reading Difference Display
                      if (_startMeterController.text.isNotEmpty &&
                          _endMeterController.text.isNotEmpty &&
                          _meterReadingDifference > 0)
                        Card(
                          elevation: 2,
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  color: Colors.blue.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Meter Reading Difference',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_meterReadingDifference.toStringAsFixed(2)} IG',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_startMeterController.text.isNotEmpty &&
                          _endMeterController.text.isNotEmpty &&
                          _meterReadingDifference > 0)
                        const SizedBox(height: 24),

                      // Refill Quantity
                      _buildRefillQuantityField(),
                      const SizedBox(height: 24),

                      // Note
                      _buildNoteField(),
                      const SizedBox(height: 32),

                      // Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
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

  Widget _buildFuelSummary() {
    final deficit = widget.requiredQty - widget.availableQty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel Requirements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Required:', style: TextStyle(color: Colors.grey)),
              Text(
                '${widget.requiredQty.toStringAsFixed(2)} IG',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available:', style: TextStyle(color: Colors.grey)),
              Text(
                '${widget.availableQty.toStringAsFixed(2)} IG',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Deficit:', style: TextStyle(color: Colors.grey)),
              Text(
                '${deficit.toStringAsFixed(2)} IG',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefillQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Refill Quantity (IG)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _refillQuantityController,
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            prefixIcon: const Icon(
              Icons.local_gas_station,
              color: Colors.orange,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _isQuantityMismatch ? Colors.orange.shade700 : Colors.grey,
                width: _isQuantityMismatch ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor:
                _isQuantityMismatch ? Colors.orange.shade50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            helperText:
                _isQuantityMismatch
                    ? '⚠️ Quantity differs from meter reading difference'
                    : null,
            helperStyle: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
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
      ],
    );
  }

  Widget _buildMeterReadings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meter Readings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
                const Text(
                  'Start Reading',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildPhotoSection(
                  'Start Photo',
                  _startMeterPhoto,
                  () => _pickImage(
                    (file) => _startMeterPhoto = file,
                    _startMeterFocusNode,
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _startMeterController,
                  focusNode: _startMeterFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Reading Value',
                    prefixIcon: const Icon(Icons.speed, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter start reading';
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
                const Text(
                  'End Reading',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildPhotoSection(
                  'End Photo',
                  _endMeterPhoto,

                  () => _pickImage(
                    (file) => _endMeterPhoto = file,
                    _endMeterFocusNode,
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _endMeterController,
                  focusNode: _endMeterFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Reading Value',
                    prefixIcon: const Icon(Icons.speed, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter end reading';
                    }
                    final endValue = int.tryParse(value) ?? 0;
                    final startValue =
                        int.tryParse(_startMeterController.text) ?? 0;
                    if (endValue <= startValue) {
                      return 'End must be greater than start';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(String label, File? photo, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: photo == null ? Colors.grey[300]! : Colors.green,
                width: photo == null ? 1 : 2,
              ),
            ),
            child:
                photo == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to capture',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isQuantityMismatch
              ? 'Reason for Quantity Difference *'
              : 'Additional Notes (Optional)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText:
                _isQuantityMismatch
                    ? 'Please explain the quantity difference...'
                    : 'Enter any notes here...',
            prefixIcon: Icon(
              Icons.note_add,
              color:
                  _isQuantityMismatch
                      ? Colors.orange.shade700
                      : Colors.blueGrey,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _isQuantityMismatch ? Colors.orange.shade700 : Colors.grey,
                width: _isQuantityMismatch ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _isQuantityMismatch ? Colors.orange.shade700 : Colors.blue,
                width: 2,
              ),
            ),
            filled: true,
            fillColor:
                _isQuantityMismatch ? Colors.orange.shade50 : Colors.white,
            helperText:
                _isQuantityMismatch
                    ? 'Please explain why the refill quantity differs from meter reading'
                    : null,
            helperStyle: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (_isQuantityMismatch &&
                (value == null || value.trim().isEmpty)) {
              return 'Please provide a reason for the quantity difference';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFuelRefill,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Colors.orange.withOpacity(0.3),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'COMPLETE REFILL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
