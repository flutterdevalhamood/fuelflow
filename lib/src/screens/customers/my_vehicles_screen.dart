import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class MyVehiclesScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const MyVehiclesScreen({super.key, required this.data});

  @override
  _MyVehiclesScreenState createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late VehicleController _vehicleController;
  Timer? _debounceTimer;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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

  // Debounce search logic
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _navigateTovehicleDetails(Map<String, dynamic> vehicle) async {
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
    // final driverController = Provider.of<DriverController>(context);
    final myVehicleData = widget.data?['my_vehicles'];
    final customerName = widget.data?['Name'] ?? 'Customer';
    final watch = context.watch<VehicleController>();
    final vehicleDetailsData = watch.vehicleData;
    final myVehicles =
        myVehicleData != null && myVehicleData is List
            ? (myVehicleData)
                .where(
                  (myVehicle) => (myVehicle['plate_no'] ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList()
            : [];
    return Scaffold(
      appBar: AppBar(title: Text(customerName)),
      body:
          myVehicleData != null
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
                    // Search Box
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
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
                    // Customer List
                    Expanded(
                      child:
                          myVehicles.isEmpty
                              ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No Vehicles registered for this customer.'
                                      : 'No results found.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: myVehicles.length,
                                itemBuilder: (context, index) {
                                  final myVehicle = myVehicles[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          _navigateTovehicleDetails(
                                            vehicleDetailsData![index],
                                          );
                                        },
                                        // contentPadding: EdgeInsets.all(8.0),
                                        leading: Container(
                                          height: 23,
                                          width: 88,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            // Replace with the actual color variable or use Colors.red
                                            borderRadius: BorderRadius.circular(
                                              23.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Plate Number",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ), // Replace 'colorwhite' with Colors.white
                                            ),
                                          ),
                                        ),
                                        title: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Text(
                                            myVehicle['plate_no'] ?? '',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge!.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Divider(
                                          color: Colors.grey,
                                          thickness: .5,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              )
              : SizedBox.shrink(),
    );
  }
}
