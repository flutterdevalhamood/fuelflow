import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_data_screen.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_colors.dart';

class FuelRefillListScreen extends StatefulWidget {
  const FuelRefillListScreen({super.key});

  @override
  State<FuelRefillListScreen> createState() => _FuelRefillListScreenState();
}

class _FuelRefillListScreenState extends State<FuelRefillListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool confirmLogout = false;
  late FuelRefillController _fuelRefillController;
  final ScrollController _scrollController = ScrollController();
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _fuelRefillController = Provider.of<FuelRefillController>(
        context,
        listen: false,
      );
      _fuelRefillController.getRefilldata().then((_) {
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
        if (!_fuelRefillController.isLoading && _fuelRefillController.hasMore) {
          _fuelRefillController.loadMore();
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

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<FuelRefillController>();
    final refillVehicleData =
        watch.refillData != null
            ? (watch.refillData ?? [])
                .where(
                  (refills) => refills['vehicle']?['plate_no']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList()
            : [];
    print('refillVehicles $refillVehicleData');
    return Consumer<FuelRefillController>(
      builder: (context, fuelRefillController, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Refilled Vehicles List')),
          body:
              watch.isLoading && isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.refillData != null
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
                              hintText: 'Search by vehicle number',
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
                              refillVehicleData.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No Refilled vehicles found'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    itemCount: refillVehicleData.length,
                                    itemBuilder: (context, index) {
                                      if (index == refillVehicleData.length) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final refillVehicle =
                                          refillVehicleData[index];
                                      return Dismissible(
                                        key: Key(
                                          refillVehicle['vehicle']?['plate_no'] ??
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
                                          final refillVehicleId =
                                              _fuelRefillController
                                                  .refillData?[index]['id'];
                                          final reason =
                                              _reasonController.text.trim();
                                          // watch.deleteVehicle(
                                          //   refillVehicleId,
                                          //   reason,
                                          // );
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
                                                refillVehicle['vehicle']?['plate_no'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                refillVehicle['driver']?['Name'] ??
                                                    'No Driver',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () async {
                                                      // await NavigationService()
                                                      //     .pushNavigation(
                                                      //       Screenroutes
                                                      //           .editDetail,
                                                      //       arguments:
                                                      //           vehicles[index],
                                                      //     );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () async {
                                                      // _deleteVehicle(index);
                                                    },
                                                  ),
                                                ],
                                              ),
                                              // onTap:
                                              //     () => _vehicleDetails(
                                              //       vehicles[index],
                                              //     ),
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
                MaterialPageRoute(builder: (context) => FuelRefillDataScreen()),
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
