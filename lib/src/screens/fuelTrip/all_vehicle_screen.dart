import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/fuelTrip/trip_return_screen.dart';
import 'package:sample/src/screens/fuelTrip/vehicle_unavailable_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class AllVehiclesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final String customerName;
  final String siteName;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic> stop;
  final Function(List<Map<String, dynamic>>)? onVehicleUpdated;
  final int? totalStops;

  const AllVehiclesScreen({
    Key? key,
    required this.vehicles,
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
  late List<Map<String, dynamic>> _vehicles;
  List<Map<String, dynamic>> _filteredVehicles = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  late TripTrackingController _trackingController;
  bool _isProcessing = false;

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<int> _selectedVehicleIds = {};

  final int _initialDisplayCount = 1;
  bool _showAllVehicles = false;

  bool get _isLastStop {
    // Check if this is the last stop in the trip
    final currentStopOrder =
        int.tryParse(widget.stop['stop_order']?.toString() ?? '0') ?? 0;

    // You'll need to pass totalStops from the previous screen
    // For now, we'll use a simple check - you should pass this in arguments
    return currentStopOrder >= (widget.totalStops ?? 1);
  }

  @override
  void initState() {
    super.initState();
    _vehicles = List.from(widget.vehicles);
    _filteredVehicles = List.from(_vehicles);
    _searchController.addListener(_filterVehicles);

    // Initialize tracking controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingController = Provider.of<TripTrackingController>(
        context,
        listen: false,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Toggle multi-select mode
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedVehicleIds.clear();
      }
    });
  }

  // Toggle vehicle selection
  void _toggleVehicleSelection(int vehicleId) {
    setState(() {
      if (_selectedVehicleIds.contains(vehicleId)) {
        _selectedVehicleIds.remove(vehicleId);
      } else {
        _selectedVehicleIds.add(vehicleId);
      }
    });
  }

  // Select all pending vehicles
  void _selectAllPending() {
    setState(() {
      _selectedVehicleIds.clear();
      for (var vehicle in _filteredVehicles) {
        final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
        if (status == 0) {
          // Only select pending vehicles
          final vehicleId =
              int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;
          if (vehicleId > 0) {
            _selectedVehicleIds.add(vehicleId);
          }
        }
      }
    });
  }

  // Mark selected vehicles as unavailable
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
        _vehicles
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
        // Update status for all selected vehicles
        for (var vehicleId in _selectedVehicleIds) {
          final index = _vehicles.indexWhere(
            (v) => v['vehicle_id'].toString() == vehicleId.toString(),
          );
          if (index != -1) {
            _vehicles[index]['status'] = '-1';
          }
        }
        _filterVehicles();
        _selectedVehicleIds.clear();
        _isMultiSelectMode = false;
      });

      widget.onVehicleUpdated?.call(_vehicles);

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

  Future<void> _handleNextAction() async {
    setState(() => _isProcessing = true);

    try {
      // Clear stored meter reading for new trip/stop
      AuthRepo.lastEndMeterReading = null;
      AuthRepo.lastTripStopId = null;
      debugPrint('✅ Cleared meter reading cache for new stop');

      if (_isLastStop) {
        // Last stop - navigate to Return to Base screen
        debugPrint('✅ Last stop completed - navigating to Return to Base');

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
                ),
          ),
        );

        // After return to base, go back to accepted assignments
        if (mounted && result == true) {
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.acceptedAssignmentScreen,
          );
        }
      } else {
        // Not last stop - move to next stop
        debugPrint('✅ Stop completed - moving to next stop');

        // Navigate back to accepted assignments to show next stop
        if (mounted) {
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.acceptedAssignmentScreen,
            // arguments: {
            //   'refresh': true,
            //   'tripId': widget.assignment['trip_id'],
            // },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stop completed! Ready for next stop.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in next action: $e');
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

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVehicles =
          _vehicles.where((vehicle) {
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
    });
  }

  int get _pendingCount {
    return _vehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == 0;
    }).length;
  }

  int get _completedCount {
    return _vehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == 1;
    }).length;
  }

  int get _unavailableCount {
    return _vehicles.where((v) {
      final status = int.tryParse(v['status']?.toString() ?? '0') ?? 0;
      return status == -1;
    }).length;
  }

  Future<void> _handleVehicleRefuel(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    debugPrint('========================================');
    debugPrint('📤 NAVIGATING TO CUSTOMER FUEL DELIVERY');
    debugPrint('========================================');
    debugPrint('Vehicle ID: $vehicleId');
    debugPrint('Plate No: $plateNo');
    debugPrint('Stop Vehicles count: ${_vehicles.length}');
    debugPrint('Vehicles list: $_vehicles'); // ADD THIS DEBUG
    debugPrint('========================================');

    final result = await NavigationService().pushNavigation(
      Screenroutes.customerFuelDeliveryScreen,
      arguments: {
        'assignmentId': widget.assignment['assignment_id'] ?? 0,
        'vehicleId': vehicleId, // ✅ Individual vehicle ID (not 0)
        'tripId': widget.assignment['trip_id']?.toString() ?? '',
        'tripStopId': widget.stop['stop_id'] ?? 0,
        'requiredQty':
            double.tryParse(widget.stop['expected_qty']?.toString() ?? '0') ??
            0.0,
        'availableQty': _toDouble(widget.assignment['available_qty']),
        'vehicleName': plateNo,
        'customerName': widget.customerName,
        'stopOrder': widget.stop['stop_order'] ?? '1',
        'currentStopIndex': 0,
        'totalStops': 1,
        'driverId': widget.assignment['driver_id'] ?? 0,
        'stopVehicles': _vehicles, // ✅ Pass the full vehicles list
        'isBulkDelivery': false, // ✅ EXPLICITLY mark as NOT bulk delivery
      },
    );

    if (result == true && mounted) {
      setState(() {
        final index = _vehicles.indexWhere(
          (v) => v['vehicle_id'].toString() == vehicle['vehicle_id'].toString(),
        );
        if (index != -1) {
          _vehicles[index]['status'] = '1';
          _filterVehicles();
        }
      });

      widget.onVehicleUpdated?.call(_vehicles);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refueling Completed $plateNo'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleVehicleUnavailable(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    // Single vehicle list
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
        final index = _vehicles.indexWhere(
          (v) => v['vehicle_id'].toString() == vehicleId.toString(),
        );
        if (index != -1) {
          _vehicles[index]['status'] = '-1';
        }
        _filterVehicles();
      });

      widget.onVehicleUpdated?.call(_vehicles);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle $plateNo marked as unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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

        // ADD THIS: Check if there are pending vehicles
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
              final shouldPop = await onWillPop();
              // onWillPop handles everything, no need to pop again
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
            // Multi-select action bar
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

            // Search Bar
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

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', _vehicles.length),
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
                          // Show "View More" button after initial vehicles
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
            // Return to Base Button (show when all vehicles are processed)
            // Return to Base / Move to Next Stop Button (show when all vehicles are processed)
            if (_pendingCount == 0 &&
                _vehicles.isNotEmpty &&
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleNextAction,
                      icon:
                          _isProcessing
                              ? const SizedBox.shrink()
                              : Icon(
                                _isLastStop
                                    ? Icons.home_outlined
                                    : Icons.arrow_forward,
                              ),
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
                                _isLastStop
                                    ? 'Return to Base'
                                    : 'Move to Next Stop',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLastStop ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

    // Override colors if selected in multi-select mode
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
                // Selection checkbox (only in multi-select mode for pending vehicles)
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

                // Vehicle Icon
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

                // Vehicle Info
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

                // Action Icons (only show for pending vehicles when NOT in multi-select mode)
                if (isPending && !_isMultiSelectMode) ...[
                  const SizedBox(width: 8),
                  // Unavailable Icon Button
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
