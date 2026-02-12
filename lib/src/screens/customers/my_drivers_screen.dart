import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class MyDriversScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const MyDriversScreen({super.key, required this.data});

  @override
  _MyDriversScreenState createState() => _MyDriversScreenState();
}

class _MyDriversScreenState extends State<MyDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  late DriverController _driverController;
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
        if (!_driverController.isLoading && _driverController.hasMore) {
          _driverController.loadMore();
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

  void _navigateTodriverDetails(Map<String, dynamic>? driver) async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.driverDetail,
      arguments: driver,
    );
    if (result == true) {
      final driverController = Provider.of<DriverController>(
        context,
        listen: false,
      );
      driverController.getDriverData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myDriverData = widget.data?['my_drivers'];
    final customerName = widget.data?['Name'] ?? 'Driver';

    final myDrivers =
        myDriverData != null && myDriverData is List
            ? (myDriverData)
                .where(
                  (myDriver) => (myDriver['Name'] ?? '').toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList()
            : [];
    return Scaffold(
      appBar: AppBar(title: Text(customerName)),
      body:
          myDriverData != null
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
                          myDrivers.isEmpty
                              ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No Drivers registered for this customer.'
                                      : 'No results found.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: myDrivers.length,
                                itemBuilder: (context, index) {
                                  final myDriver = myDrivers[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          _navigateTodriverDetails(myDriver);
                                        },

                                        leading: Container(
                                          height: 23,
                                          width: 88,
                                          decoration: BoxDecoration(
                                            color: Colors.green,

                                            borderRadius: BorderRadius.circular(
                                              23.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Driver Name",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Text(
                                            myDriver['Name'] ?? '',
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
