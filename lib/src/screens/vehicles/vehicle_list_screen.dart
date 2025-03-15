import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _HomeScreenState extends State<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool confirmLogout = false;
  late VehicleController _vehicleController;
  final ScrollController _scrollController = ScrollController();
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
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

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_vehicleController.isLoading && _vehicleController.hasMore) {
          _vehicleController.loadMore();
          showInfoSnack('Loading...');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _deleteVehicle(int index) {
    final vehicleId = _vehicleController.vehicleData?[index]['id'];

    print('vehicleiodddd $vehicleId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Vehicle"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // To make the dialog compact
            children: [
              Text("Are you sure you want to delete this vehicle?"),
              SizedBox(height: 16), // Add some spacing
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3, // Allow multiple lines for the reason
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
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
                } else {
                  // Show an error or prompt the user to enter a reason
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

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<VehicleController>();
    final vehicles =
        watch.vehicleData != null
            ? (watch.vehicleData ?? [])
                .where(
                  (vehicle) =>
                      vehicle['plate_no'].toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (vehicle['type']?['Name']?.toLowerCase() ?? '').contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList()
            : [];
    print('vehiclesss $vehicles');
    return Consumer<VehicleController>(
      builder: (context, VehicleController, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Vehicle List')),
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
                          child:
                              vehicles.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No vehicles registered yet.'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    itemCount: vehicles.length,
                                    itemBuilder: (context, index) {
                                      if (index == vehicles.length) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final vehicle = vehicles[index];
                                      return Dismissible(
                                        key: Key(
                                          vehicle['plate_no'] ??
                                              index.toString(),
                                        ),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: Colors.red,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          alignment: Alignment.centerRight,
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onDismissed: (direction) {
                                          final vehicleId =
                                              _vehicleController
                                                  .vehicleData?[index]['id'];
                                          final reason =
                                              _reasonController.text.trim();
                                          watch.deleteVehicle(
                                            vehicleId,
                                            reason,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          child: Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ListTile(
                                              contentPadding: EdgeInsets.all(
                                                16,
                                              ),
                                              leading: Icon(
                                                Icons.directions_car,
                                                size: 30,
                                                color: Colors.blue,
                                              ),
                                              title: Text(
                                                vehicle['plate_no'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                vehicle['type']?['Name'] ??
                                                    'No Type',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: () async {
                                                      await NavigationService()
                                                          .pushNavigation(
                                                            Screenroutes
                                                                .vehicleRefill,
                                                            arguments: vehicle,
                                                          );
                                                    },
                                                    icon: Icon(
                                                      Icons.local_gas_station,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () async {
                                                      await NavigationService()
                                                          .pushNavigation(
                                                            Screenroutes
                                                                .editDetail,
                                                            arguments:
                                                                vehicles[index],
                                                          );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () async {
                                                      _deleteVehicle(index);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              onTap:
                                                  () => _vehicleDetails(
                                                    vehicles[index],
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  )
                  : SizedBox.shrink(),

          floatingActionButton: FloatingActionButton(
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
