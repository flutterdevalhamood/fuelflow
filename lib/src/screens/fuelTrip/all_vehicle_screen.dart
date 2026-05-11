import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/fuelTrip/trip_return_screen.dart';
import 'package:sample/src/screens/fuelTrip/vehicle_unavailable_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../../util/refill_state.dart';

class AllVehiclesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stopVehicles;
  final String customerName;
  final String siteName;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic> stop;
  final Function(List<Map<String, dynamic>>)? onVehicleUpdated;
  final int? totalStops;

  const AllVehiclesScreen({
    Key? key,
    required this.stopVehicles,
    required this.customerName,
    required this.siteName,
    required this.assignment,
    required this.stop,
    this.onVehicleUpdated,
    this.totalStops,
  }) : super(key: key);

  @override
  State<AllVehiclesScreen> createState() => _AllVehiclesScreenState();
}

class _AllVehiclesScreenState extends State<AllVehiclesScreen> {
  late List<Map<String, dynamic>> stopVehicles;
  List<Map<String, dynamic>> _filteredVehicles = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  late TripTrackingController _trackingController;
  bool _isProcessing = false;

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<int> _selectedVehicleIds = {};

  final int _initialDisplayCount = 5;
  bool _showAllVehicles = false;

  bool _isScreenReady = false;

  bool get _isLastStop {
    final currentStopOrder =
        int.tryParse(widget.stop['stop_order']?.toString() ?? '0') ?? 0;
    return currentStopOrder >= (widget.totalStops ?? 1);
  }

  double _totalQuantityUsed = 0.0;

  /// Whether the driver's tank is depleted but pending vehicles remain.
  bool get _isFuelDeficient {
    final currentAvailableQty =
        _toDouble(widget.assignment['available_qty']) - _totalQuantityUsed;
    return currentAvailableQty <= 0 && _pendingCount > 0;
  }

  @override
  void initState() {
    super.initState();
    stopVehicles = List.from(widget.stopVehicles);
    _filteredVehicles = List.from(stopVehicles);
    _searchController.addListener(_filterVehicles);

    _totalQuantityUsed = 0.0;
    AuthRepo.lastEndMeterReading = null;
    AuthRepo.lastTripStopId = null;
    AuthRepo.lastAvailableQty = null;
    AuthRepo.lastEndMeterPhotoPath = null;
    AuthRepo.refuelStartedGloballyLogged = false;
    AuthRepo.arrivedAtStopLogged = false;
    debugPrint('✅ Cleared AuthRepo data on screen entry');

    AuthRepo.refuelStartedGloballyLogged = false;
    debugPrint(
      '✅ Cleared AuthRepo data and reset global event flags on screen entry',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingController = Provider.of<TripTrackingController>(
        context,
        listen: false,
      );

      setState(() => _isScreenReady = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    AuthRepo.lastEndMeterReading = null;
    AuthRepo.lastTripStopId = null;
    AuthRepo.lastAvailableQty = null;
    AuthRepo.lastEndMeterPhotoPath = null;
    debugPrint('✅ Cleared AuthRepo data on screen exit');

    super.dispose();
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedVehicleIds.clear();
      }
    });
  }

  void _toggleVehicleSelection(int vehicleId) {
    setState(() {
      if (_selectedVehicleIds.contains(vehicleId)) {
        _selectedVehicleIds.remove(vehicleId);
      } else {
        _selectedVehicleIds.add(vehicleId);
      }
    });
  }

  void _selectAllPending() {
    setState(() {
      _selectedVehicleIds.clear();
      for (var vehicle in _filteredVehicles) {
        final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
        if (status == 0) {
          final vehicleId =
              int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;
          if (vehicleId > 0) {
            _selectedVehicleIds.add(vehicleId);
          }
        }
      }
    });
  }

  Future<void> _markSelectedAsUnavailable() async {
    if (_selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedVehicles =
        stopVehicles
            .where(
              (v) => _selectedVehicleIds.contains(
                int.tryParse(v['vehicle_id']?.toString() ?? '0'),
              ),
            )
            .toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BulkVehicleUnavailableScreen(
              vehicleIds: _selectedVehicleIds.toList(),
              vehicles: selectedVehicles,
              tripStopId: widget.stop['stop_id'] ?? 0,
              customerName: widget.customerName,
              siteName: widget.siteName,
            ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        for (var vehicleId in _selectedVehicleIds) {
          final index = stopVehicles.indexWhere(
            (v) => v['vehicle_id'].toString() == vehicleId.toString(),
          );
          if (index != -1) {
            stopVehicles[index]['status'] = '-1';
          }
        }
        _filterVehicles();
        _selectedVehicleIds.clear();
        _isMultiSelectMode = false;
      });

      widget.onVehicleUpdated?.call(stopVehicles);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedVehicleIds.length} vehicles marked as unavailable',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ─── Return to Base ──────────────────────────────────────────────────────

  Future<void> _handleReturnToBase() async {
    setState(() => _isProcessing = true);

    try {
      if (_isFuelDeficient) {
        await _trackingController.logManualTripEvent(
          eventType: 'moving_towards_base_due_to_fuel_deficiency',
        );
        debugPrint('✅ Logged: moving_towards_base_due_to_fuel_deficiency');
      }

      // ADD THIS: Log refuel_completed when returning to base
      await _trackingController.logCriticalTripEvent(
        eventType: 'refuel_completed',
      );
      debugPrint('✅ Logged: refuel_completed (return to base)');

      AuthRepo.lastEndMeterReading = null;
      AuthRepo.lastTripStopId = null;
      AuthRepo.lastAvailableQty = null;
      AuthRepo.lastEndMeterPhotoPath = null;
      debugPrint('✅ Cleared meter reading cache');
      debugPrint('✅ Navigating to Return to Base');

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TripReturnScreen(
                tripId:
                    int.tryParse(
                      widget.assignment['trip_id']?.toString() ?? '0',
                    ) ??
                    0,
                assignmentId: widget.assignment['assignment_id'] ?? 0,
                vehicleId: widget.assignment['vehicle_id'] ?? 0,
                driverId: widget.assignment['driver_id'] ?? 0,
                customerName: widget.customerName,
                completedCount: _completedCount,
                unavailableCount: _unavailableCount,
                isLastStop: _isLastStop,
              ),
        ),
      );

      if (mounted && result == true) {
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.acceptedAssignmentScreen,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in return to base: $e');
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

  // ─── Request Admin Refill ────────────────────────────────────────────────

  /// Opens the admin-refill dialog. The dialog itself handles the API call.
  Future<void> _handleRequestAdminRefill() async {
    if (!mounted) return;

    /// Compute the shortage as a positive number to pre-fill the dialog.
    final currentAvailable =
        _toDouble(widget.assignment['available_qty']) - _totalQuantityUsed;
    final shortage = currentAvailable < 0 ? currentAvailable.abs() : 0.0;

    /// Grab the driver's current location before opening the dialog so the
    /// user doesn't have to wait while it's fetched.
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('⚠️ Could not fetch position for admin refill: $e');
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => RequestAdminRefillDialog(
            vehicleId: widget.assignment['vehicle_id']?.toString() ?? '',
            shortageQty: shortage,
            position: position,
            pendingCount: _pendingCount,
          ),
    );
  }

  // ─── Filtering ───────────────────────────────────────────────────────────

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _applyFiltersWithoutNavigating();
    });

    if (!_isScreenReady) return;

    // ✅ Only auto-navigate when truly settled and no navigation is in progress
    if (_pendingCount == 0 &&
        stopVehicles.isNotEmpty &&
        !_isLastStop &&
        !_isProcessing) {
      // ✅ Use a small delay so the current frame fully renders before navigating
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _pendingCount == 0 && !_isProcessing) {
          debugPrint(
            '✅ All vehicles completed - navigating to accepted assignments',
          );
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.acceptedAssignmentScreen,
          );
        }
      });
    }
  }

  // void _filterVehicles() {
  //   final query = _searchController.text.toLowerCase();
  //   setState(() {
  //     _filteredVehicles =
  //         stopVehicles.where((vehicle) {
  //           final plateNo = vehicle['plate_no']?.toString().toLowerCase() ?? '';
  //           final status =
  //               int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
  //
  //           final matchesSearch = query.isEmpty || plateNo.contains(query);
  //
  //           bool matchesStatus = true;
  //           if (_selectedFilter == 'pending') {
  //             matchesStatus = status == 0;
  //           } else if (_selectedFilter == 'completed') {
  //             matchesStatus = status == 1;
  //           } else if (_selectedFilter == 'unavailable') {
  //             matchesStatus = status == -1;
  //           }
  //
  //           return matchesSearch && matchesStatus;
  //         }).toList();
  //   });
  //
  //   if (_pendingCount == 0 &&
  //       stopVehicles.isNotEmpty &&
  //       !_isLastStop &&
  //       !_isProcessing) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (mounted) {
  //         debugPrint(
  //           '✅ All vehicles completed - auto-navigating to accepted assignments',
  //         );
  //         NavigationService().pushAndRemoveUntilNavigation(
  //           Screenroutes.acceptedAssignmentScreen,
  //         );
  //       }
  //     });
  //   }
  // }

  // ─── Counts ──────────────────────────────────────────────────────────────

  int get _pendingCount {
    return stopVehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == 0;
    }).length;
  }

  int get _completedCount {
    return stopVehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == 1;
    }).length;
  }

  int get _unavailableCount {
    return stopVehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == -1;
    }).length;
  }

  // ─── Vehicle actions ─────────────────────────────────────────────────────

  Future<void> _handleVehicleRefuel(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final stopVehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;
    final stopVehiclePlateNumber =
        int.tryParse(vehicle['plate_no']?.toString() ?? '0') ?? 0;

    final originalAvailableQty = _toDouble(widget.assignment['available_qty']);
    final currentAvailableQty = originalAvailableQty - _totalQuantityUsed;

    if (currentAvailableQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient fuel available in vehicle.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await NavigationService().pushNavigation(
      Screenroutes.customerFuelDeliveryScreen,
      arguments: {
        'assignmentId': widget.assignment['assignment_id'] ?? 0,
        'vehicleId': widget.assignment['vehicle_id'],
        'tripId': widget.assignment['trip_id']?.toString() ?? '',
        'tripStopId': widget.stop['stop_id'] ?? 0,
        'requiredQty':
            double.tryParse(widget.stop['expected_qty']?.toString() ?? '0') ??
            0.0,
        'availableQty': currentAvailableQty,
        'vehicleName': plateNo,
        'customerName': widget.customerName,
        'stopOrder': widget.stop['stop_order'] ?? '1',
        'currentStopIndex': 0,
        'totalStops': 1,
        'driverId': widget.assignment['driver_id'] ?? 0,
        'stopVehicles': stopVehicles,
        'isBulkDelivery': false,
        'stopVehicleId': stopVehicleId,
        'stopVehiclePlateNumber': stopVehiclePlateNumber,
      },
    );

    // ✅ Guard: don't update state if widget is gone
    if (!mounted) return;

    if (result == true) {
      // ✅ Calculate quantity delivered BEFORE any setState
      double quantityDelivered = 0;
      if (AuthRepo.lastAvailableQty != null) {
        quantityDelivered = currentAvailableQty - AuthRepo.lastAvailableQty!;
        debugPrint('✅ Quantity delivered: $quantityDelivered');
      }

      // ✅ Find updated index BEFORE setState
      final index = stopVehicles.indexWhere(
        (v) => v['vehicle_id'].toString() == vehicle['vehicle_id'].toString(),
      );

      // ✅ Single setState — batch ALL updates together to prevent glitch
      setState(() {
        if (quantityDelivered > 0) {
          _totalQuantityUsed += quantityDelivered;
        }
        if (index != -1) {
          stopVehicles[index] = Map<String, dynamic>.from(stopVehicles[index])
            ..['status'] = '1';
        }
        // ✅ Rebuild filtered list inline instead of calling _filterVehicles()
        // to avoid the postFrameCallback auto-navigation triggering mid-rebuild
        _applyFiltersWithoutNavigating();
      });

      widget.onVehicleUpdated?.call(stopVehicles);

      // ✅ Show snackbar AFTER setState settles
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refueling Completed for $plateNo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  void _applyFiltersWithoutNavigating() {
    final query = _searchController.text.toLowerCase();
    _filteredVehicles =
        stopVehicles.where((vehicle) {
          final plateNo = vehicle['plate_no']?.toString().toLowerCase() ?? '';
          final status =
              int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
          final matchesSearch = query.isEmpty || plateNo.contains(query);
          bool matchesStatus = true;
          if (_selectedFilter == 'pending') {
            matchesStatus = status == 0;
          } else if (_selectedFilter == 'completed') {
            matchesStatus = status == 1;
          } else if (_selectedFilter == 'unavailable') {
            matchesStatus = status == -1;
          }
          return matchesSearch && matchesStatus;
        }).toList();
  }

  Future<void> _handleVehicleUnavailable(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    final selectedVehicles = [vehicle];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BulkVehicleUnavailableScreen(
              vehicleIds: [vehicleId],
              vehicles: selectedVehicles,
              tripStopId: widget.stop['stop_id'] ?? 0,
              customerName: widget.customerName,
              siteName: widget.siteName,
            ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final index = stopVehicles.indexWhere(
          (v) => v['vehicle_id'].toString() == vehicleId.toString(),
        );
        if (index != -1) {
          stopVehicles[index]['status'] = '-1';
        }
        _filterVehicles();
      });

      widget.onVehicleUpdated?.call(stopVehicles);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle $plateNo marked as unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ─── Utility ─────────────────────────────────────────────────────────────

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<bool> onWillPop() async {
    if (_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = false;
        _selectedVehicleIds.clear();
      });
      return false;
    }

    if (_pendingCount > 0) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Incomplete Deliveries'),
              content: Text(
                'You have $_pendingCount vehicle(s) pending. '
                'Are you sure you want to go back?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
      );

      if (shouldPop == true) {
        NavigationService().navigateToUntil(
          Screenroutes.acceptedAssignmentScreen,
        );
      }
      return false;
    }

    NavigationService().navigateToUntil(Screenroutes.acceptedAssignmentScreen);
    return false;
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedVehicleIds.clear();
          });
          return false;
        }

        if (_pendingCount > 0) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Incomplete Deliveries'),
                  content: Text(
                    'You have $_pendingCount vehicle(s) pending. '
                    'Are you sure you want to go back?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Stay'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
          );

          if (shouldPop == true) {
            NavigationService().navigateToUntil(
              Screenroutes.acceptedAssignmentScreen,
            );
            return false;
          }
          return false;
        }

        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.acceptedAssignmentScreen,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isMultiSelectMode
                ? '${_selectedVehicleIds.length} Selected'
                : 'All Vehicles',
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await onWillPop();
            },
          ),
          actions: [
            if (_pendingCount > 0)
              IconButton(
                icon: Icon(
                  _isMultiSelectMode ? Icons.close : Icons.checklist_rtl,
                ),
                tooltip:
                    _isMultiSelectMode
                        ? 'Cancel Selection'
                        : 'Multi-Select Mode',
                onPressed: _toggleMultiSelectMode,
              ),
            if (_isMultiSelectMode && _pendingCount > 0)
              TextButton(
                onPressed: _selectAllPending,
                child: const Text(
                  'Select All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Multi-select action bar ─────────────────────────────────
            if (_isMultiSelectMode && _selectedVehicleIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedVehicleIds.length} vehicle(s) selected',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _markSelectedAsUnavailable,
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Mark Unavailable'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by plate number...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),

            // ── Filter chips ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', stopVehicles.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending', _pendingCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed', _completedCount),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Unavailable',
                      'unavailable',
                      _unavailableCount,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Vehicle list ────────────────────────────────────────────
            Expanded(
              child:
                  _filteredVehicles.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No vehicles found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _showAllVehicles
                                ? _filteredVehicles.length
                                : (_filteredVehicles.length >
                                        _initialDisplayCount
                                    ? _initialDisplayCount + 1
                                    : _filteredVehicles.length),
                        itemBuilder: (context, index) {
                          if (!_showAllVehicles &&
                              _filteredVehicles.length > _initialDisplayCount &&
                              index == _initialDisplayCount) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllVehicles = true;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.expand_more,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View All ${_filteredVehicles.length} Vehicles',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final vehicle = _filteredVehicles[index];
                          return _buildVehicleCard(vehicle);
                        },
                      ),
            ),

            // ── Bottom action panel ─────────────────────────────────────
            // Shown when: all vehicles are done  OR  fuel is depleted.
            if (((_pendingCount == 0 && stopVehicles.isNotEmpty) ||
                    (_toDouble(widget.assignment['available_qty']) -
                            _totalQuantityUsed <=
                        0)) &&
                !_isMultiSelectMode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Fuel-depleted warning banner ────────────────
                      if (_isFuelDeficient)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Fuel depleted with $_pendingCount vehicle(s) pending. '
                                  'Return to base or request an admin refill.',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Request Admin Refill button (only when deficit) ─
                      if (_isFuelDeficient) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isProcessing
                                    ? null
                                    : _handleRequestAdminRefill,
                            icon: const Icon(Icons.support_agent),
                            label: const Text(
                              'Request Admin Vehicle Refill',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // ── Return to Base button ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _handleReturnToBase,
                          icon:
                              _isProcessing
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.home_outlined),
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
                                  : const Text(
                                    'Return to Base',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
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
              ),
          ],
        ),
      ),
    );
  }

  // ─── Reusable widgets ────────────────────────────────────────────────────

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _filterVehicles();
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final statusValue = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    final isUnavailable = statusValue == -1;
    final isPending = statusValue == 0;
    final isCompleted = statusValue == 1;
    final isSelected = _selectedVehicleIds.contains(vehicleId);

    Color borderColor;
    Color bgColor;
    Color iconColor;
    String statusLabel;
    IconData statusIcon;

    if (isUnavailable) {
      borderColor = Colors.red.shade300;
      bgColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      statusLabel = 'Unavailable';
      statusIcon = Icons.block;
    } else if (isCompleted) {
      borderColor = Colors.green.shade300;
      bgColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle;
    } else {
      borderColor = Colors.amber.shade400;
      bgColor = Colors.amber.shade50;
      iconColor = Colors.amber.shade700;
      statusLabel = 'Pending';
      statusIcon = Icons.pending;
    }

    if (_isMultiSelectMode && isSelected) {
      borderColor = Colors.blue.shade700;
      bgColor = Colors.blue.shade100;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: _isMultiSelectMode && isSelected ? 3 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isMultiSelectMode && isPending) {
            _toggleVehicleSelection(vehicleId);
          } else if (!_isMultiSelectMode && isPending) {
            _handleVehicleRefuel(vehicle);
          }
        },
        onLongPress:
            isPending && !_isMultiSelectMode
                ? () {
                  setState(() {
                    _isMultiSelectMode = true;
                    _selectedVehicleIds.add(vehicleId);
                  });
                }
                : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isMultiSelectMode && isPending) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleVehicleSelection(vehicleId);
                    },
                    activeColor: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Icon(Icons.directions_car, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plateNo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: iconColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPending && !_isMultiSelectMode) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _handleVehicleUnavailable(vehicle),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.block,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RequestAdminRefillDialog – self-contained dialog with the API call
// ═══════════════════════════════════════════════════════════════════════════

class RequestAdminRefillDialog extends StatefulWidget {
  /// The driver's vehicle ID (from the active assignment).
  final String vehicleId;

  /// Pre-computed shortage quantity (always ≥ 0).
  final double shortageQty;

  /// Current GPS position (may be null if fetch failed).
  final Position? position;

  /// How many customer vehicles are still waiting.
  final int pendingCount;

  const RequestAdminRefillDialog({
    Key? key,
    required this.vehicleId,
    required this.shortageQty,
    required this.position,
    required this.pendingCount,
  }) : super(key: key);

  @override
  State<RequestAdminRefillDialog> createState() =>
      _RequestAdminRefillDialogState();
}

class _RequestAdminRefillDialogState extends State<RequestAdminRefillDialog> {
  late final TextEditingController _qtyController;
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the shortage amount (minimum they need).
    _qtyController = TextEditingController(
      text: widget.shortageQty.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── validation ─────────────────────────────────────────────────────────

  bool get _isValid {
    final qty = double.tryParse(_qtyController.text.trim());
    return qty != null && qty > 0;
  }

  // In _RequestAdminRefillDialogState class, update the _submitRequest() method:

  // In _RequestAdminRefillDialogState class, update the _submitRequest() method:

  Future<void> _submitRequest() async {
    if (!_isValid) {
      setState(() {
        _errorMessage = 'Please enter a valid quantity greater than 0.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final trackingController = Provider.of<TripTrackingController>(
        context,
        listen: false,
      );

      Position? currentPosition = widget.position;
      if (currentPosition == null) {
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('⚠️ Could not fetch position: $e');
          throw Exception('Could not get current location. Please try again.');
        }
      }

      final result = await trackingController
          .requestAdminVehicleRefilingForShortage(
            vehicleId: widget.vehicleId,
            expectedQuantity: double.parse(_qtyController.text.trim()),
            position: currentPosition,
            notes:
                _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
          );

      if (result['success'] == true) {
        debugPrint('✅ Admin refill request submitted via controller');

        if (mounted) {
          // SET FLAG - Admin refill was requested
          RefillState.isAwaitingAdminRefill = true;

          // Close the dialog first
          Navigator.of(context).pop();

          // Navigate to AcceptedAssignmentScreen
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.acceptedAssignmentScreen,
          );

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    'Request sent successfully. Please proceed to refill your vehicle from admin.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to send request');
      }
    } on Exception catch (e) {
      debugPrint('❌ Admin refill request failed: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    } catch (e) {
      debugPrint('❌ Admin refill request failed: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Amber header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.amber.shade700,
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Admin Refill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your vehicle fuel is insufficient for pending deliveries',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Info row: pending vehicles --
                _InfoRow(
                  icon: Icons.pending_outlined,
                  label: 'Pending Vehicles',
                  value: '${widget.pendingCount}',
                  iconColor: Colors.amber.shade700,
                ),
                const SizedBox(height: 8),

                // -- Info row: shortage --
                _InfoRow(
                  icon: Icons.local_gas_station,
                  label: 'Fuel Shortage',
                  value: '${widget.shortageQty.toStringAsFixed(2)} G',
                  iconColor: Colors.red.shade600,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Expected Quantity field ──────────────────────────
                Text(
                  'Expected Refill Quantity (G) *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_gas_station),
                    suffixText: 'G',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (_) => setState(() {}), // rebuild for _isValid
                ),

                const SizedBox(height: 16),

                // ── Notes field ──────────────────────────────────────
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Urgent – 3 vehicles waiting at site…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),

                // ── Inline error message ─────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Action buttons ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            (_isSubmitting || !_isValid)
                                ? null
                                : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Send Request',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small helper widget that renders a single labelled info row inside the
/// dialog (icon + label on the left, value on the right).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
