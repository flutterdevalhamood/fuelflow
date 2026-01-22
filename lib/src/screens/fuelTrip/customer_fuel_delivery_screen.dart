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
  final int driverId;

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

  final ImagePicker _picker = ImagePicker();

  late TripTrackingController _trackingController;
  late FuelTripController _fuelTripController;
  late FuelRefillBeforeTripController _refillController;

  bool _dialogProcessing = false;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isSubmitting = false;

  bool _arrivedAtStopLogged = false;
  bool _customerLoadingStartedLogged = false;
  bool _customerLoadingCompletedLogged = false;
  bool _driverNotesAddedLogged = false;

  // New flags for delivery buttons
  bool _refuelStartedLogged = false;
  bool _refuelCompletedLogged = false;
  bool _deliveryStarted = false;
  bool _deliveryEnded = false;

  // Calculate meter reading difference
  int get _meterReadingDifference {
    final startValue = int.tryParse(_startMeterController.text) ?? 0;
    final endValue = int.tryParse(_endMeterController.text) ?? 0;
    return endValue - startValue;
  }

  // Check if quantity matches meter difference
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

  // NEW: Start Delivery Button Handler
  Future<void> _handleStartDelivery() async {
    if (_deliveryStarted || _refuelStartedLogged) return;

    // Validate start meter reading and photo
    if (_startMeterController.text.isEmpty) {
      _showSnackBar('Please enter start meter reading');
      return;
    }

    if (_startMeterPhoto == null) {
      _showSnackBar('Please capture start meter photo');
      return;
    }

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

  // NEW: End Delivery Button Handler
  Future<void> _handleEndDelivery() async {
    if (_deliveryEnded || _refuelCompletedLogged) return;

    if (!_deliveryStarted) {
      _showSnackBar('Please start delivery first');
      return;
    }

    // Validate end meter reading and photo
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

    setState(() => _isSubmitting = true);

    try {
      final success = await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_completed',
      );

      if (success) {
        setState(() {
          _refuelCompletedLogged = true;
          _deliveryEnded = true;
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
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() => onPicked(File(image.path)));

        // Auto-focus the next text field after image is selected
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

    if (_startMeterPhoto == null || _endMeterPhoto == null) {
      _showSnackBar('Please capture both meter photos');
      return;
    }

    if (!_deliveryEnded) {
      _showSnackBar('Please end delivery before completing');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ LOG REQUEST DATA BEFORE API CALL
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
      debugPrint('Start Meter Photo Path: ${_startMeterPhoto!.path}');
      debugPrint('End Meter Photo Path: ${_endMeterPhoto!.path}');
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
        customerStartMeterFiles: [_startMeterPhoto!],
        customerEndMeterReadingValue:
            int.tryParse(_endMeterController.text) ?? 0,
        customerEndMeterFiles: [_endMeterPhoto!],
        note: _noteController.text,
        vehicleTankStartReadingValue: 0,
        vehicleStartMeterFiles: const [],
        vehicleTankEndReadingValue: 0,
        vehicleEndMeterFiles: const [],
      );

      // ✅ LOG RESPONSE
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

      await _trackingController.logManualTripEvent(
        eventType: 'departed_from_stop',
      );
      debugPrint('✅ Logged: departed_from_stop');

      final isLastStop = widget.currentStopIndex >= widget.totalStops - 1;

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showCompletionDialog(isLastStop);
      }
    } catch (e) {
      // ✅ LOG ERROR
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

  void _showCompletionDialog(bool isLastStop) {
    if (!mounted) return;

    _dialogProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return PopScope(
                canPop: !_dialogProcessing,
                child: AlertDialog(
                  title: const Text('Stop Completed'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastStop
                            ? 'All stops completed! Moving towards base.'
                            : 'Moving towards next stop.',
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
                      ElevatedButton(
                        onPressed: () {
                          if (Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          }

                          if (mounted) {
                            // ✅ Return true to indicate completion
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: const Text('OK'),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<void> _navigateToAcceptedAssignmentScreen() async {
    NavigationService().pushAndRemoveUntilNavigation(
      Screenroutes.acceptedAssignmentScreen,
      removeUntilPageName: Screenroutes.dashboard,
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

                            // START METER SECTION - Hidden after delivery started
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
                                        () => _pickImage((file) {
                                          _startMeterPhoto = file;
                                          _onStartMeterChanged();
                                        }, _startMeterFocusNode),
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
                                      const SizedBox(height: 16),

                                      // START DELIVERY BUTTON
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

                            // START METER SUMMARY - Shown after delivery started
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

                            // END METER SECTION - Only shown after delivery started but before delivery ended
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

                                      // END DELIVERY BUTTON
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

                            // END METER SUMMARY - Shown after delivery ended
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

                            // Delivery Quantity and Notes sections only shown after delivery started
                            if (_deliveryStarted) ...[
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
                                  if (qty < widget.requiredQty) {
                                    return 'Quantity cannot be less than required (${widget.requiredQty.toStringAsFixed(2)} IG)';
                                  }
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

                    // Complete Delivery Button - Only shown after delivery started
                    if (_deliveryStarted)
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

  Widget _buildPhotoSection(String label, File? photo, VoidCallback? onTap) {
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
                          onTap == null ? 'Photo captured' : 'Tap to capture',
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
