import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_before_trip_controller.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/fuelTrip/trip_return_screen.dart';
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
  final int driverId;
  final List<dynamic>? stopVehicles;
  final bool? isBulkDelivery;

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
    required this.driverId,
    this.stopVehicles,
    this.isBulkDelivery,
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

  final _startMeterFocusNode = FocusNode();
  final _endMeterFocusNode = FocusNode();

  File? _startMeterPhoto;
  File? _endMeterPhoto;

  // NEW: List for additional images
  List<File> _additionalImages = [];

  final ImagePicker _picker = ImagePicker();

  late TripTrackingController _trackingController;
  late FuelTripController _fuelTripController;
  late FuelRefillBeforeTripController _refillController;

  bool _dialogProcessing = false;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isSubmitting = false;

  bool _showDeliveryFields = false;

  bool _arrivedAtStopLogged = false;
  bool _customerLoadingStartedLogged = false;
  bool _customerLoadingCompletedLogged = false;
  bool _driverNotesAddedLogged = false;

  bool _refuelStartedLogged = false;
  bool _refuelCompletedLogged = false;
  bool _deliveryStarted = false;
  bool _deliveryEnded = false;

  bool _isStartMeterPreFilled = false;

  int get _meterReadingDifference {
    final startValue = int.tryParse(_startMeterController.text) ?? 0;
    final endValue = int.tryParse(_endMeterController.text) ?? 0;
    return endValue - startValue;
  }

  bool get _isQuantityMismatch {
    if (_deliveryQuantityController.text.isEmpty) return false;
    final deliveryQty = double.tryParse(_deliveryQuantityController.text) ?? 0;
    return deliveryQty != _meterReadingDifference.toDouble();
  }

  @override
  void initState() {
    super.initState();

    _trackingController = context.read<TripTrackingController>();
    _fuelTripController = context.read<FuelTripController>();
    _refillController = context.read<FuelRefillBeforeTripController>();

    // UPDATED: Use AuthRepo and mark as pre-filled
    if (AuthRepo.lastTripStopId == widget.tripStopId &&
        AuthRepo.lastEndMeterReading != null) {
      _startMeterController.text = AuthRepo.lastEndMeterReading!;
      _isStartMeterPreFilled = true; // ADD THIS FLAG
      debugPrint(
        '✅ Pre-filled start meter from previous vehicle: ${_startMeterController.text}',
      );
    }

    _startMeterController.addListener(_onStartMeterChanged);
    _endMeterController.addListener(_onEndMeterChanged);
    _noteController.addListener(_onNoteChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  Future<void> _initializeTracking() async {
    if (!mounted || _arrivedAtStopLogged) return;

    try {
      await _trackingController.startTripTracking(
        tripId: int.parse(widget.tripId),
        tripStopId: widget.tripStopId,
        eventType: 'arrived_at_stop',
      );

      _arrivedAtStopLogged = true;
      debugPrint('✅ Logged: arrived_at_stop');
    } catch (e) {
      debugPrint('❌ Tracking init failed: $e');
    }
  }

  void _onStartMeterChanged() {
    if (_startMeterController.text.isNotEmpty &&
        !_customerLoadingStartedLogged &&
        _startMeterPhoto != null) {
      _logCustomerLoadingStarted();
    }
    setState(() {});
  }

  Future<void> _logCustomerLoadingStarted() async {
    if (_customerLoadingStartedLogged) return;

    try {
      final success = await _trackingController.logManualTripEvent(
        eventType: 'customer_loading_started',
      );

      if (success) {
        _customerLoadingStartedLogged = true;
        debugPrint('✅ Logged: customer_loading_started');
      }
    } catch (e) {
      debugPrint('❌ Failed to log customer_loading_started: $e');
    }
  }

  void _onEndMeterChanged() {
    if (_endMeterController.text.isNotEmpty &&
        !_customerLoadingCompletedLogged &&
        _endMeterPhoto != null &&
        _customerLoadingStartedLogged) {
      _logCustomerLoadingCompleted();
    }
    setState(() {});
  }

  Future<void> _logCustomerLoadingCompleted() async {
    if (_customerLoadingCompletedLogged) return;

    try {
      final success = await _trackingController.logManualTripEvent(
        eventType: 'customer_loading_completed',
      );

      if (success) {
        _customerLoadingCompletedLogged = true;
        debugPrint('✅ Logged: customer_loading_completed');
      }
    } catch (e) {
      debugPrint('❌ Failed to log customer_loading_completed: $e');
    }
  }

  void _onNoteChanged() {
    if (_noteController.text.isNotEmpty && !_driverNotesAddedLogged) {
      _logDriverNotesAdded();
    }
  }

  Future<void> _logDriverNotesAdded() async {
    if (_driverNotesAddedLogged) return;

    try {
      final success = await _trackingController.logManualTripEvent(
        eventType: 'driver_notes_added',
      );

      if (success) {
        _driverNotesAddedLogged = true;
        debugPrint('✅ Logged: driver_notes_added');
      }
    } catch (e) {
      debugPrint('❌ Failed to log driver_notes_added: $e');
    }
  }

  Future<void> _handleStartDelivery() async {
    if (_deliveryStarted || _refuelStartedLogged) return;

    if (_startMeterController.text.isEmpty) {
      _showSnackBar('Please enter start meter reading');
      return;
    }

    // UPDATED: Only check for photo if NOT pre-filled
    if (!_isStartMeterPreFilled && _startMeterPhoto == null) {
      _showSnackBar('Please capture start meter photo');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Start Refueling'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please confirm the following details:'),
                const SizedBox(height: 12),
                Text(
                  'Start Meter Reading: ${_startMeterController.text} IG',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // UPDATED: Conditional text based on pre-fill status
                Text(
                  _isStartMeterPreFilled
                      ? 'Start meter reading from previous vehicle'
                      : 'Start meter photo has been captured',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Once confirmed, you cannot modify these details.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm & Start'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_started',
      );

      if (success) {
        setState(() {
          _refuelStartedLogged = true;
          _deliveryStarted = true;
        });
        _showSnackBar(
          'Delivery started successfully',
          backgroundColor: Colors.green,
        );
        debugPrint('✅ Logged: refuel_started');
      } else {
        _showSnackBar(
          'Failed to log delivery start',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('❌ Error logging refuel_started: $e');
      _showSnackBar('Error starting delivery', backgroundColor: Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleEndDelivery() async {
    if (_deliveryEnded || _refuelCompletedLogged) return;

    if (!_deliveryStarted) {
      _showSnackBar('Please start delivery first');
      return;
    }

    if (_endMeterController.text.isEmpty) {
      _showSnackBar('Please enter end meter reading');
      return;
    }

    if (_endMeterPhoto == null) {
      _showSnackBar('Please capture end meter photo');
      return;
    }

    final endValue = int.tryParse(_endMeterController.text);
    final startValue = int.tryParse(_startMeterController.text);
    if (endValue != null && startValue != null && endValue <= startValue) {
      _showSnackBar('End reading must be greater than start reading');
      return;
    }

    final meterDifference = endValue! - startValue!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm End Refueling'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please confirm the following details:'),
                const SizedBox(height: 12),
                Text(
                  'Start Meter Reading: ${_startMeterController.text} IG',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'End Meter Reading: ${_endMeterController.text} IG',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meter Difference: $meterDifference IG',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'End meter photo has been captured',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Once confirmed, you cannot modify these details.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
                child: const Text('Confirm & End'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_completed',
      );

      if (success) {
        setState(() {
          _refuelCompletedLogged = true;
          _deliveryEnded = true;
          _showDeliveryFields = true;
        });
        _showSnackBar(
          'Delivery ended successfully',
          backgroundColor: Colors.green,
        );
        debugPrint('✅ Logged: refuel_completed');
      } else {
        _showSnackBar(
          'Failed to log delivery end',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('❌ Error logging refuel_completed: $e');
      _showSnackBar('Error ending delivery', backgroundColor: Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 60, // Reduced from 85
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty && mounted) {
        // Limit number of additional images
        if (_additionalImages.length + images.length > 5) {
          _showSnackBar(
            'Maximum 5 additional images allowed',
            backgroundColor: Colors.orange,
          );
          return;
        }

        // Check total file size
        int totalSize = 0;
        final newFiles = <File>[];

        for (var img in images) {
          final file = File(img.path);
          final size = await file.length();
          totalSize += size;
          newFiles.add(file);
        }

        if (totalSize > 10 * 1024 * 1024) {
          // 10MB total limit
          _showSnackBar(
            'Total image size too large. Please select fewer or smaller images.',
            backgroundColor: Colors.orange,
          );
          return;
        }

        setState(() {
          _additionalImages.addAll(newFiles);
        });

        _showSnackBar(
          '${images.length} image(s) added',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar('Failed to pick images');
    }
  }

  // NEW: Remove an additional image
  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _startMeterController.removeListener(_onStartMeterChanged);
    _endMeterController.removeListener(_onEndMeterChanged);
    _noteController.removeListener(_onNoteChanged);

    _startMeterController.dispose();
    _endMeterController.dispose();
    _deliveryQuantityController.dispose();
    _noteController.dispose();

    _startMeterFocusNode.dispose();
    _endMeterFocusNode.dispose();

    super.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _pickImage(Function(File) onPicked, FocusNode? focusNode) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        final file = File(image.path);

        // Check file size before accepting
        final fileSize = await file.length();
        debugPrint('📸 Selected image size: $fileSize bytes');

        if (fileSize > 5 * 1024 * 1024) {
          // 5MB limit
          _showSnackBar(
            'Image too large. Please select a smaller image.',
            backgroundColor: Colors.orange,
          );
          return;
        }

        setState(() => onPicked(file));

        if (focusNode != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              FocusScope.of(context).requestFocus(focusNode);
            }
          });
        }

        if (onPicked.toString().contains('_startMeterPhoto')) {
          _onStartMeterChanged();
        } else if (onPicked.toString().contains('_endMeterPhoto')) {
          _onEndMeterChanged();
        }
      }
    } catch (e) {
      _showSnackBar('Image pick failed');
    }
  }

  Future<void> _submitFuelDelivery() async {
    if (!mounted || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // UPDATED: Only validate end meter photo and start meter photo if NOT pre-filled
    if (!_isStartMeterPreFilled && _startMeterPhoto == null) {
      _showSnackBar('Please capture start meter photo');
      return;
    }

    if (_endMeterPhoto == null) {
      _showSnackBar('Please capture end meter photo');
      return;
    }

    if (!_deliveryEnded) {
      _showSnackBar('Please end delivery before completing');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('========================================');
      debugPrint('📤 FUEL DELIVERY REQUEST');
      debugPrint('========================================');
      debugPrint('Vehicle ID: ${widget.vehicleId}');
      debugPrint('Trip ID: ${widget.tripId}');
      debugPrint('Trip Stop ID: ${widget.tripStopId}');
      debugPrint('Type: outflow');
      debugPrint('Quantity: ${double.parse(_deliveryQuantityController.text)}');
      debugPrint('Before Quantity: ${widget.availableQty}');
      debugPrint(
        'After Quantity: ${widget.availableQty - double.parse(_deliveryQuantityController.text)}',
      );
      debugPrint(
        'Customer Start Meter: ${int.tryParse(_startMeterController.text) ?? 0}',
      );
      debugPrint(
        'Customer End Meter: ${int.tryParse(_endMeterController.text) ?? 0}',
      );
      debugPrint('Note: ${_noteController.text}');
      debugPrint('Start Meter Pre-filled: $_isStartMeterPreFilled');
      debugPrint(
        'Start Meter Photo Path: ${_startMeterPhoto?.path ?? "N/A (pre-filled)"}',
      );
      debugPrint('End Meter Photo Path: ${_endMeterPhoto!.path}');
      debugPrint('Additional Images Count: ${_additionalImages.length}');
      debugPrint('========================================');

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
        customerStartMeterFiles:
            _isStartMeterPreFilled ? [] : [_startMeterPhoto!],
        customerEndMeterReadingValue:
            int.tryParse(_endMeterController.text) ?? 0,
        customerEndMeterFiles: [_endMeterPhoto!],
        note: _noteController.text,
        vehicleTankStartReadingValue: 0,
        vehicleStartMeterFiles: const [],
        vehicleTankEndReadingValue: 0,
        vehicleEndMeterFiles: const [],
        additionalFiles: _additionalImages,
      );

      debugPrint('========================================');
      debugPrint('📥 FUEL DELIVERY RESPONSE');
      debugPrint('========================================');
      debugPrint('Success: $success');
      debugPrint('========================================');

      if (!success || !mounted) {
        _showSnackBar('Delivery failed', backgroundColor: Colors.red);
        setState(() => _isSubmitting = false);
        return;
      }

      AuthRepo.lastEndMeterReading = _endMeterController.text;
      AuthRepo.lastTripStopId = widget.tripStopId;
      debugPrint(
        '✅ Saved end meter reading for next vehicle: ${_endMeterController.text}',
      );

      await _trackingController.logManualTripEvent(
        eventType: 'departed_from_stop',
      );
      debugPrint('✅ Logged: departed_from_stop');

      // ✅ CORRECTED: Determine if it's the last stop based on stop_order vs total trip_stops
      // Pass both flags to the dialog
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showCompletionDialog(widget.currentStopIndex, widget.totalStops);
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ FUEL DELIVERY ERROR');
      debugPrint('========================================');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: ${StackTrace.current}');
      debugPrint('========================================');

      _showSnackBar('Error occurred', backgroundColor: Colors.red);
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCompletionDialog(int currentStopIndex, int totalStops) {
    if (!mounted) return;

    _dialogProcessing = false;

    // ✅ Calculate isLastStop correctly
    final isLastStop = (currentStopIndex + 1) >= totalStops;

    debugPrint('========================================');
    debugPrint('🎯 SHOW COMPLETION DIALOG');
    debugPrint('========================================');
    debugPrint('widget.vehicleId: ${widget.vehicleId}');
    debugPrint('widget.stopVehicles: ${widget.stopVehicles}');
    debugPrint(
      'widget.stopVehicles length: ${widget.stopVehicles?.length ?? 0}',
    );
    debugPrint('widget.isBulkDelivery: ${widget.isBulkDelivery}');
    debugPrint('isLastStop: $isLastStop');
    debugPrint('currentStopIndex: $currentStopIndex');
    debugPrint('totalStops: $totalStops');
    debugPrint('========================================');

    // ✅ CORRECTED LOGIC with multiple checks:
    final bool isBulkDelivery;

    if (widget.isBulkDelivery != null) {
      // 1. If explicitly set by caller, use that value
      isBulkDelivery = widget.isBulkDelivery!;
      debugPrint('🔍 Using explicit isBulkDelivery flag: $isBulkDelivery');
    } else if (widget.stopVehicles != null && widget.stopVehicles!.isNotEmpty) {
      // 2. If stop_vehicles has data, it's individual vehicle delivery
      isBulkDelivery = false;
      debugPrint('🔍 stop_vehicles has data -> Individual delivery');
    } else {
      // 3. Fallback: if stop_vehicles is null or empty, check vehicleId
      // If vehicleId > 0 but stopVehicles is null, it's likely an individual delivery
      // where stopVehicles wasn't passed correctly
      // If vehicleId == 0, it's definitely bulk delivery
      isBulkDelivery = widget.vehicleId == 0;
      debugPrint(
        '🔍 Fallback check - vehicleId: ${widget.vehicleId} -> isBulkDelivery: $isBulkDelivery',
      );
    }

    final hasPendingVehicles =
        widget.stopVehicles?.any((vehicle) {
          final status =
              int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
          return status == 0;
        }) ??
        false;

    // ✅ Decision logic:
    // 1. Individual vehicle delivery (stop_vehicles not empty OR vehicleId > 0) -> Always return to AllVehiclesScreen
    // 2. Bulk delivery (stop_vehicles empty AND vehicleId == 0) + Last stop -> Navigate to Return to Base
    // 3. Bulk delivery (stop_vehicles empty AND vehicleId == 0) + Not last stop -> Navigate to Accepted Assignments

    final isIndividualVehicleDelivery = !isBulkDelivery;
    final shouldShowReturnToBase = isBulkDelivery && isLastStop;

    debugPrint('🔍 isBulkDelivery: $isBulkDelivery');
    debugPrint('🔍 hasPendingVehicles: $hasPendingVehicles');
    debugPrint('🔍 isIndividualVehicleDelivery: $isIndividualVehicleDelivery');
    debugPrint('🔍 shouldShowReturnToBase: $shouldShowReturnToBase');
    debugPrint('========================================');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return PopScope(
                canPop: !_dialogProcessing,
                child: AlertDialog(
                  title: const Text('Delivery Completed'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isIndividualVehicleDelivery
                            ? 'Vehicle refueled successfully!'
                            : (isLastStop
                                ? 'Bulk delivery completed! This was the final stop.'
                                : 'Bulk delivery completed! Ready for next stop.'),
                      ),
                      if (_dialogProcessing) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Finalizing...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (!_dialogProcessing)
                      ElevatedButton.icon(
                        onPressed: () async {
                          debugPrint(
                            '✅ Dialog button pressed - isIndividualVehicleDelivery: $isIndividualVehicleDelivery, isLastStop: $isLastStop, shouldShowReturnToBase: $shouldShowReturnToBase',
                          );

                          Navigator.of(ctx).pop();

                          if (mounted) {
                            // ✅ PRIORITY 1: Individual vehicle delivery - ALWAYS return to AllVehiclesScreen
                            if (isIndividualVehicleDelivery) {
                              debugPrint(
                                '✅ Individual vehicle delivery - returning to AllVehiclesScreen with result=true',
                              );
                              Navigator.of(context).pop(true);
                              return;
                            }

                            // ✅ PRIORITY 2: Bulk delivery + Last stop = Navigate to Return to Base
                            if (shouldShowReturnToBase) {
                              debugPrint(
                                '✅ Bulk delivery, last stop - navigating to Return to Base',
                              );
                              await _navigateToReturnScreen();
                              return;
                            }

                            // ✅ PRIORITY 3: Bulk delivery + Not last stop = Go back to Accepted Assignments
                            debugPrint(
                              '✅ Bulk delivery, not last stop - returning to Accepted Assignments',
                            );
                            NavigationService().pushAndRemoveUntilNavigation(
                              Screenroutes.acceptedAssignmentScreen,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Stop completed! Ready for next stop.',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isIndividualVehicleDelivery
                              ? Icons.check_circle
                              : (shouldShowReturnToBase
                                  ? Icons.home_outlined
                                  : Icons.arrow_forward),
                        ),
                        label: Text(
                          isIndividualVehicleDelivery
                              ? 'OK'
                              : (shouldShowReturnToBase
                                  ? 'Return to Base'
                                  : 'Next Stop'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isIndividualVehicleDelivery
                                  ? Colors.green
                                  : (shouldShowReturnToBase
                                      ? Colors.blue
                                      : Colors.green),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
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

  Future<void> _navigateToReturnScreen() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TripReturnScreen(
                tripId: int.tryParse(widget.tripId) ?? 0,
                assignmentId: widget.assignmentId,
                vehicleId: widget.vehicleId,
                driverId: widget.driverId,
                customerName: widget.customerName,
                completedCount: 1,
                unavailableCount: 0,
              ),
        ),
      );

      // ✅ CORRECTED: After returning from TripReturnScreen, don't automatically navigate
      // The TripReturnScreen already handles navigation to acceptedAssignmentScreen
      // when "Reached Base" is pressed, so we don't need to do anything here
      debugPrint('✅ Returned from TripReturnScreen with result: $result');
    } catch (e) {
      debugPrint('❌ Error navigating to return screen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
                                    Text(
                                      widget.customerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.vehicleName,
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

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
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

                            const Text(
                              'Customer Meter Readings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // START METER SECTION
                            if (!_deliveryStarted) ...[
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildPhotoSection(
                                        'Start Meter Photo',
                                        _startMeterPhoto,
                                        _isStartMeterPreFilled // ADD THIS CONDITION
                                            ? null // Disable photo capture if pre-filled
                                            : () => _pickImage((file) {
                                              _startMeterPhoto = file;
                                              _onStartMeterChanged();
                                            }, _startMeterFocusNode),
                                        isLocked:
                                            _isStartMeterPreFilled, // ADD THIS PARAMETER
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
                                        focusNode: _startMeterFocusNode,
                                        enabled: !_isStartMeterPreFilled,
                                        // ADD THIS LINE
                                        decoration: InputDecoration(
                                          labelText: 'Reading Value',
                                          prefixIcon: const Icon(Icons.speed),
                                          suffixIcon:
                                              _isStartMeterPreFilled // ADD THIS
                                                  ? Icon(
                                                    Icons.lock,
                                                    color:
                                                        Colors.orange.shade700,
                                                    size: 20,
                                                  )
                                                  : null,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor:
                                              _isStartMeterPreFilled // ADD THIS
                                                  ? Colors.orange.shade50
                                                  : Colors.grey.shade50,
                                          helperText:
                                              _isStartMeterPreFilled // ADD THIS
                                                  ? 'Pre-filled from previous vehicle'
                                                  : null,
                                          helperStyle: TextStyle(
                                            // ADD THIS
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                      const SizedBox(height: 16),

                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : _handleStartDelivery,
                                          icon:
                                              _isSubmitting
                                                  ? const SizedBox.shrink()
                                                  : const Icon(
                                                    Icons.play_arrow,
                                                  ),
                                          label:
                                              _isSubmitting
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : const Text(
                                                    'Start Refueling',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _isSubmitting
                                                    ? Colors.grey
                                                    : Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // START METER SUMMARY
                            if (_deliveryStarted) ...[
                              Card(
                                elevation: 2,
                                color: Colors.green.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.green.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Start Meter Reading',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_startMeterController.text} IG',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // END METER SECTION
                            if (_deliveryStarted && !_deliveryEnded) ...[
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildPhotoSection(
                                        'End Meter Photo',
                                        _endMeterPhoto,
                                        () => _pickImage((file) {
                                          _endMeterPhoto = file;
                                          _onEndMeterChanged();
                                        }, _endMeterFocusNode),
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
                                        focusNode: _endMeterFocusNode,
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
                                      const SizedBox(height: 16),

                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isSubmitting
                                                  ? null
                                                  : _handleEndDelivery,
                                          icon:
                                              _isSubmitting
                                                  ? const SizedBox.shrink()
                                                  : const Icon(Icons.stop),
                                          label:
                                              _isSubmitting
                                                  ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : const Text(
                                                    'End Refueling',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _isSubmitting
                                                    ? Colors.grey
                                                    : Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // END METER SUMMARY
                            if (_deliveryEnded) ...[
                              Card(
                                elevation: 2,
                                color: Colors.green.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.green.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'End Meter Reading',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_endMeterController.text} IG',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Meter Reading Difference Display
                            if (_startMeterController.text.isNotEmpty &&
                                _endMeterController.text.isNotEmpty &&
                                _meterReadingDifference > 0 &&
                                _deliveryStarted)
                              Card(
                                elevation: 2,
                                color: Colors.orange.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.orange.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calculate,
                                        color: Colors.orange.shade700,
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
                                                color: Colors.orange.shade700,
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
                                _meterReadingDifference > 0 &&
                                _deliveryStarted)
                              const SizedBox(height: 24),

                            // NEW: Additional Images Section (Only after delivery started)
                            if (_showDeliveryFields) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Additional Images (Optional)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickAdditionalImages,
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Add Images'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_additionalImages.isNotEmpty)
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _additionalImages.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                _additionalImages[index],
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap:
                                                    () =>
                                                        _removeAdditionalImage(
                                                          index,
                                                        ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          color: Colors.grey.shade400,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'No additional images added',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
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
                                  helperText:
                                      _isQuantityMismatch
                                          ? '⚠️ Quantity differs from meter reading difference'
                                          : null,
                                  helperStyle: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    return 'Cannot exceed available quantity (${widget.availableQty.toStringAsFixed(2)} IG)';
                                  }
                                  // if (qty < widget.requiredQty) {
                                  //   return 'Quantity cannot be less than required (${widget.requiredQty.toStringAsFixed(2)} IG)';
                                  // }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),

                              const SizedBox(height: 24),

                              TextFormField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  labelText:
                                      _isQuantityMismatch
                                          ? 'Reason for Quantity Difference *'
                                          : 'Note (Optional)',
                                  prefixIcon: Icon(
                                    Icons.note,
                                    color:
                                        _isQuantityMismatch
                                            ? Colors.orange.shade700
                                            : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        _isQuantityMismatch
                                            ? BorderSide(
                                              color: Colors.orange.shade700,
                                              width: 1.5,
                                            )
                                            : const BorderSide(),
                                  ),
                                  filled: true,
                                  fillColor:
                                      _isQuantityMismatch
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade50,
                                  helperText:
                                      _isQuantityMismatch
                                          ? 'Please explain why the delivery quantity differs from meter reading'
                                          : null,
                                  helperStyle: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (_isQuantityMismatch &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please provide a reason for the quantity difference';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Complete Delivery Button
                    if (_showDeliveryFields)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : _submitFuelDelivery,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Refueling Completed',
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

  Widget _buildPhotoSection(
    String label,
    File? photo,
    VoidCallback? onTap, {
    bool isLocked = false, // ADD THIS PARAMETER
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // WRAP Text in Row
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (isLocked) ...[
              // ADD THIS
              const SizedBox(width: 8),
              Icon(Icons.lock, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                '(From previous vehicle)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLocked ? null : onTap, // UPDATED
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLocked ? Colors.orange.shade50 : Colors.grey.shade100,
              // UPDATED
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isLocked
                        ? Colors.orange.shade300
                        : Colors.grey.shade300, // UPDATED
              ),
            ),
            child:
                photo == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLocked ? Icons.lock : Icons.camera_alt, // UPDATED
                          size: 40,
                          color:
                              isLocked
                                  ? Colors.orange.shade400
                                  : Colors.grey.shade400, // UPDATED
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLocked // UPDATED
                              ? 'Photo from previous vehicle'
                              : (onTap == null
                                  ? 'Photo captured'
                                  : 'Tap to capture'),
                          style: TextStyle(
                            color:
                                isLocked
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade600, // UPDATED
                            fontWeight:
                                isLocked
                                    ? FontWeight.w600
                                    : FontWeight.normal, // UPDATED
                          ),
                        ),
                      ],
                    )
                    : Stack(
                      // UPDATED - Add lock overlay if locked
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(photo, fit: BoxFit.cover),
                        ),
                        if (isLocked)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lock,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
