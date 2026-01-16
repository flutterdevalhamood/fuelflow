import 'package:flutter/material.dart';
import 'package:sample/src/screens/fuelTrip/vehicle_unavailable_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class AllVehiclesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final String customerName;
  final String siteName;
  final Map<String, dynamic> assignment;
  final Map<String, dynamic> stop;
  final Function(List<Map<String, dynamic>>) onVehicleUpdated;

  const AllVehiclesScreen({
    Key? key,
    required this.vehicles,
    required this.customerName,
    required this.siteName,
    required this.assignment,
    required this.stop,
    required this.onVehicleUpdated,
  }) : super(key: key);

  @override
  State<AllVehiclesScreen> createState() => _AllVehiclesScreenState();
}

class _AllVehiclesScreenState extends State<AllVehiclesScreen> {
  late List<Map<String, dynamic>> _vehicles;
  List<Map<String, dynamic>> _filteredVehicles = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, pending, completed, unavailable

  @override
  void initState() {
    super.initState();
    _vehicles = List.from(widget.vehicles);
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
      _filteredVehicles =
          _vehicles.where((vehicle) {
            final plateNo = vehicle['plate_no']?.toString().toLowerCase() ?? '';
            final status =
                int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;

            // Apply search filter
            final matchesSearch = query.isEmpty || plateNo.contains(query);

            // Apply status filter
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
        }
      });

      widget.onVehicleUpdated(_vehicles);

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
            (context) => VehicleUnavailableScreen(
              vehicleId: vehicleId,
              plateNo: plateNo,
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
        }
      });

      widget.onVehicleUpdated(_vehicles);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Vehicles'), elevation: 0),
      body: Column(
        children: [
          // // Statistics Header
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.blue.shade400, Colors.blue.shade700],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //   ),
          //   child: Column(
          //     children: [
          //       Text(
          //         widget.customerName,
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       const SizedBox(height: 4),
          //       Text(
          //         widget.siteName,
          //         style: const TextStyle(color: Colors.white70, fontSize: 14),
          //       ),
          //       const SizedBox(height: 16),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceAround,
          //         children: [
          //           _buildStatChip('Total', _vehicles.length, Colors.white),
          //           _buildStatChip('Pending', _pendingCount, Colors.orange),
          //           _buildStatChip('Done', _completedCount, Colors.green),
          //           _buildStatChip('N/A', _unavailableCount, Colors.red),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),

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
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
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

          // Vehicle List
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
                      itemCount: _filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _filteredVehicles[index];
                        return _buildVehicleCard(vehicle);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
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

    final isUnavailable = statusValue == -1;
    final isPending = statusValue == 0;
    final isCompleted = statusValue == 1;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
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

              // Action Icons (only show for pending vehicles)
              if (isPending) ...[
                const SizedBox(width: 8),
                // Refuel Icon Button
                Material(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _handleVehicleRefuel(vehicle),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
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
    );
  }
}
