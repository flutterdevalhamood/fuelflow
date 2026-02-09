import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/vehicles/vehicle_registration_screen.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../../providers/vehicle_controller.dart';
import '../../util/snack.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<VehicleListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool confirmLogout = false;
  late VehicleController _vehicleController;
  final ScrollController _adminScrollController = ScrollController();
  final ScrollController _customerScrollController = ScrollController();
  bool isInitialLoad = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollControllers();
      _vehicleController = Provider.of<VehicleController>(
        context,
        listen: false,
      );
      _vehicleController.getVehicleData().then((_) {
        setState(() {
          isInitialLoad = false;
        });
      });
    });
  }

  void _setupScrollControllers() {
    // Admin scroll controller
    _adminScrollController.addListener(() {
      if (_adminScrollController.offset >=
              _adminScrollController.position.maxScrollExtent &&
          !_adminScrollController.position.outOfRange) {
        _loadMoreIfNeeded();
      }
    });

    // Customer scroll controller
    _customerScrollController.addListener(() {
      if (_customerScrollController.offset >=
              _customerScrollController.position.maxScrollExtent &&
          !_customerScrollController.position.outOfRange) {
        _loadMoreIfNeeded();
      }
    });
  }

  void _loadMoreIfNeeded() {
    if (!_vehicleController.isLoading && _vehicleController.hasMore) {
      showInfoSnack('Loading more vehicles...');
      _vehicleController.loadMore();
    }
  }

  // Pull-to-refresh handler
  Future<void> _onRefresh() async {
    try {
      await _vehicleController.getVehicleData();

      // Clear search when refreshing
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      }
    } catch (e) {
      print('Error during refresh: $e');
      if (mounted) {
        showInfoSnack('Failed to refresh data');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _debounceTimer?.cancel();
    _adminScrollController.dispose();
    _customerScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _deleteVehicle(int index, List<Map<String, dynamic>> vehicles) {
    final vehicleId = vehicles[index]['id'];

    print('vehicleiodddd $vehicleId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Vehicle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to delete this vehicle?"),
              SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                print('reasonfordelete $reason');
                if (reason.isNotEmpty) {
                  if (vehicleId != null) {
                    await _vehicleController.deleteVehicle(vehicleId, reason);
                  }
                  print("Deleting vehicle with reason: $reason");
                  Navigator.pop(context);
                  showSuccessSnack('Vehicle Deleted Successfully');
                  _reasonController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please enter a reason for deletion"),
                    ),
                  );
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _vehicleDetails(Map<String, dynamic> vehicle) async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.vehicleDetail,
      arguments: vehicle,
    );

    if (result == true) {
      final vehicleController = Provider.of<VehicleController>(
        context,
        listen: false,
      );
      vehicleController.getVehicleData();
    }
  }

  List<Map<String, dynamic>> _filterVehicles(
    List<Map<String, dynamic>>? allVehicles,
    bool isAdminTab,
  ) {
    if (allVehicles == null) return [];

    return allVehicles.where((vehicle) {
      // Filter by admin status
      final isAdmin = vehicle['customer']?['is_admin'] == "1";
      if (isAdminTab && !isAdmin) return false;
      if (!isAdminTab && isAdmin) return false;

      // Apply search filter
      if (_searchQuery.isEmpty) return true;

      final plateNo = vehicle['plate_no']?.toLowerCase() ?? '';
      final typeName = vehicle['type']?['Name']?.toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();

      return plateNo.contains(searchLower) || typeName.contains(searchLower);
    }).toList();
  }

  Widget _buildVehicleList(
    List<Map<String, dynamic>> vehicles,
    ScrollController scrollController,
    bool isLoading,
    bool hasMore,
  ) {
    return vehicles.isEmpty
        ? RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No vehicles registered yet.\nPull down to refresh.'
                      : 'No results found.\nPull down to refresh.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        )
        : ListView.builder(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: vehicles.length + (isLoading && hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == vehicles.length) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final vehicle = vehicles[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(
                    Icons.directions_car,
                    size: 30,
                    color: Colors.blue,
                  ),
                  title: Text(
                    vehicle['plate_no'] ?? 'Unknown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle['type']?['Name'] ?? 'No Type',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        vehicle['is_active'] == "1" ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              vehicle['is_active'] == "1"
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Add customer name for debugging
                      Text(
                        'Customer: ${vehicle['customer']?['Name'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing:
                      AuthRepo.role == "customer" || AuthRepo.role == "operator"
                          ? SizedBox.shrink()
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await NavigationService().pushNavigation(
                                    Screenroutes.editDetail,
                                    arguments: vehicle,
                                  );
                                },
                              ),
                              SizedBox(width: 8),
                              Switch(
                                value: vehicle['is_active'] == "1",
                                onChanged: (bool newValue) async {
                                  await _vehicleController.toggleVehicleStatus(
                                    vehicle['id'],
                                  );
                                  final status =
                                      newValue ? 'Active' : 'Inactive';
                                  showSuccessSnack(
                                    'Vehicle status set to $status',
                                  );
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                              ),
                            ],
                          ),
                  onTap: () => _vehicleDetails(vehicle),
                ),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<VehicleController>();

    return Consumer<VehicleController>(
      builder: (context, vehicleController, child) {
        final adminVehicles = _filterVehicles(watch.vehicleData, true);
        final customerVehicles = _filterVehicles(watch.vehicleData, false);

        return Scaffold(
          appBar: AppBar(
            title: Text('Vehicle List'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'Admin Vehicles (${adminVehicles.length})',
                  icon: Icon(Icons.admin_panel_settings),
                ),
                Tab(
                  text: 'Customer Vehicles (${customerVehicles.length})',
                  icon: Icon(Icons.people),
                ),
              ],
            ),
          ),
          body:
              watch.isLoading && isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.vehicleData != null
                  ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: Colors.blue,
                      backgroundColor: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by type or vehicle number',
                                hintStyle: TextStyle(
                                  color: Appcolors.textLightGrayColor(context),
                                ),
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildVehicleList(
                                  adminVehicles,
                                  _adminScrollController,
                                  watch.isLoading,
                                  watch.hasMore,
                                ),
                                _buildVehicleList(
                                  customerVehicles,
                                  _customerScrollController,
                                  watch.isLoading,
                                  watch.hasMore,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : SizedBox.shrink(),
          floatingActionButton:
              AuthRepo.role == "customer"
                  ? SizedBox.shrink()
                  : FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleRegistrationScreen(),
                        ),
                      );
                    },
                    child: Icon(Icons.add),
                  ),
        );
      },
    );
  }
}
