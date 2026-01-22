import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/trip_tracking_controller.dart';
import 'package:sample/src/screens/fuelTrip/all_vehicle_screen.dart';
import 'package:sample/src/screens/fuelTrip/vehicle_unavailable_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class CustomerStopVehicleScreen extends StatefulWidget {
  final List<dynamic> stopVehicles;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic> stop;
  final String customerName;
  final String siteName;

  const CustomerStopVehicleScreen({
    Key? key,
    required this.stopVehicles,
    required this.assignment,
    required this.stop,
    required this.customerName,
    required this.siteName,
  }) : super(key: key);

  @override
  State<CustomerStopVehicleScreen> createState() =>
      _CustomerStopVehicleScreenState();
}

class _CustomerStopVehicleScreenState extends State<CustomerStopVehicleScreen> {
  late List<Map<String, dynamic>> _vehicles;
  List<Map<String, dynamic>> _filteredVehicles = [];
  bool _hasChanges = false;
  bool _isCompletingStop = false;
  final TextEditingController _searchController = TextEditingController();
  final int _initialDisplayCount = 1; // Show only 5 vehicles initially

  @override
  void initState() {
    super.initState();
    _vehicles =
        widget.stopVehicles
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
    _filteredVehicles = List.from(_vehicles);
    _searchController.addListener(_filterVehicles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = List.from(_vehicles);
      } else {
        _filteredVehicles =
            _vehicles.where((vehicle) {
              final plateNo =
                  vehicle['plate_no']?.toString().toLowerCase() ?? '';
              return plateNo.contains(query);
            }).toList();
      }
    });
  }

  // Check if all vehicles are processed (completed or unavailable)
  bool get _allVehiclesProcessed {
    return _vehicles.every((vehicle) {
      final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
      return status == 1 || status == -1; // completed or unavailable
    });
  }

  // Count pending vehicles
  int get _pendingCount {
    return _vehicles.where((vehicle) {
      final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
      return status == 0;
    }).length;
  }

  // Count completed vehicles
  int get _completedCount {
    return _vehicles.where((vehicle) {
      final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
      return status == 1;
    }).length;
  }

  // Count unavailable vehicles
  int get _unavailableCount {
    return _vehicles.where((vehicle) {
      final status = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
      return status == -1;
    }).length;
  }

  void _navigateToAllVehicles() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AllVehiclesScreen(
              vehicles: _vehicles,
              customerName: widget.customerName,
              siteName: widget.siteName,
              assignment: widget.assignment,
              stop: widget.stop,
              onVehicleUpdated: (updatedVehicles) {
                setState(() {
                  _vehicles = updatedVehicles;
                  _filterVehicles();
                  _hasChanges = true;
                });
              },
            ),
      ),
    );
  }

  Future<void> _handleVehicleRefuel(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    final result = await NavigationService().pushNavigation(
      Screenroutes.customerFuelDeliveryScreen,
      arguments: {
        'assignmentId': widget.assignment['assignment_id'] ?? 0,
        'vehicleId': vehicleId,
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
          _hasChanges = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery completed for $plateNo'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleVehicleUnavailable(Map<String, dynamic> vehicle) async {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final vehicleId =
        int.tryParse(vehicle['vehicle_id']?.toString() ?? '0') ?? 0;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BulkVehicleUnavailableScreen(
              vehicleIds: [],
              vehicles: [],
              tripStopId: widget.stop['stop_id'] ?? 0,
              customerName: widget.customerName,
              siteName: widget.siteName,
            ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final index = _vehicles.indexWhere(
          (v) => v['vehicle_id'].toString() == vehicle['vehicle_id'].toString(),
        );
        if (index != -1) {
          _vehicles[index]['status'] = '-1';
          _filterVehicles();
          _hasChanges = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle $plateNo marked as unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleCompleteStop() async {
    if (_pendingCount > 0) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Incomplete Deliveries'),
              content: Text(
                'You have $_pendingCount vehicle(s) still pending. '
                'Are you sure you want to complete this stop?',
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
                  ),
                  child: const Text('Complete Anyway'),
                ),
              ],
            ),
      );

      if (shouldContinue != true) return;
    }

    setState(() {
      _isCompletingStop = true;
    });

    try {
      final trackingController = Provider.of<TripTrackingController>(
        context,
        listen: false,
      );

      final success = await trackingController.logManualTripEvent(
        eventType: 'refuel_completed',
        description:
            _vehicles.isEmpty
                ? 'Stop completed at ${widget.customerName} (No vehicles)'
                : 'Stop completed at ${widget.customerName} ($_completedCount/${_vehicles.length} vehicles completed)',
      );

      if (!success) {
        debugPrint('⚠️ Failed to log refuel completed event');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Failed to log completion event'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _vehicles.isEmpty
                  ? 'Stop completed successfully (No vehicles)'
                  : 'Stop completed successfully ($_completedCount/${_vehicles.length} vehicles delivered)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error completing stop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing stop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingStop = false;
        });
      }
    }
  }

  Widget _buildSummaryRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final displayedVehicles =
        _filteredVehicles.length > _initialDisplayCount
            ? _filteredVehicles.take(_initialDisplayCount).toList()
            : _filteredVehicles;
    final hasMoreVehicles = _filteredVehicles.length > _initialDisplayCount;

    return WillPopScope(
      onWillPop: () async {
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
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Vehicle Deliveries'), elevation: 0),
        body: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
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
                          Icons.location_on,
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
                              widget.siteName,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusChip('Total', _vehicles.length, Colors.white),
                      _buildStatusChip('Pending', _pendingCount, Colors.orange),
                      _buildStatusChip('Done', _completedCount, Colors.green),
                    ],
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

            // Vehicle List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayedVehicles.length + (hasMoreVehicles ? 1 : 0),
                itemBuilder: (context, index) {
                  if (hasMoreVehicles && index == displayedVehicles.length) {
                    // "View All" button
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: OutlinedButton(
                        onPressed: _navigateToAllVehicles,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            Icon(Icons.list, color: Colors.blue.shade700),
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

                  final vehicle = displayedVehicles[index];
                  return _buildVehicleCard(vehicle);
                },
              ),
            ),

            // // Complete Stop Button
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.grey.shade300,
            //         blurRadius: 10,
            //         offset: const Offset(0, -2),
            //       ),
            //     ],
            //   ),
            //   child: SafeArea(
            //     child: SizedBox(
            //       width: double.infinity,
            //       child: ElevatedButton(
            //         onPressed: _isCompletingStop ? null : _handleCompleteStop,
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.green,
            //           foregroundColor: Colors.white,
            //           padding: const EdgeInsets.symmetric(vertical: 16),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           elevation: 2,
            //         ),
            //         child:
            //             _isCompletingStop
            //                 ? const SizedBox(
            //                   height: 20,
            //                   width: 20,
            //                   child: CircularProgressIndicator(
            //                     strokeWidth: 2,
            //                     valueColor: AlwaysStoppedAnimation<Color>(
            //                       Colors.white,
            //                     ),
            //                   ),
            //                 )
            //                 : Row(
            //                   mainAxisAlignment: MainAxisAlignment.center,
            //                   children: [
            //                     const Icon(
            //                       Icons.check_circle_outline,
            //                       size: 24,
            //                     ),
            //                     const SizedBox(width: 8),
            //                     Text(
            //                       _allVehiclesProcessed
            //                           ? 'Complete Stop'
            //                           : 'Complete Stop ($_pendingCount Pending)',
            //                       style: const TextStyle(
            //                         fontSize: 16,
            //                         fontWeight: FontWeight.w600,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final plateNo = vehicle['plate_no']?.toString() ?? 'N/A';
    final statusValue = int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;

    final isUnavailable = statusValue == -1;
    final isPending = statusValue == 0;
    final isCompleted = statusValue == 1;

    Color borderColor;
    Color bgColor;
    Color iconColor;
    String? statusLabel;
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: isPending ? () => _handleVehicleRefuel(vehicle) : null,
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

                // // Action Icons (only show for pending vehicles)
                // if (isPending) ...[
                //   const SizedBox(width: 8),
                //   // Unavailable Icon Button
                //   Material(
                //     color: Colors.red,
                //     borderRadius: BorderRadius.circular(8),
                //     child: InkWell(
                //       onTap: () => _handleVehicleUnavailable(vehicle),
                //       borderRadius: BorderRadius.circular(8),
                //       child: Container(
                //         padding: const EdgeInsets.all(12),
                //         child: const Icon(
                //           Icons.block,
                //           color: Colors.white,
                //           size: 24,
                //         ),
                //       ),
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
