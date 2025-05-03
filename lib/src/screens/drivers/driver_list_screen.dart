import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_navigation.dart';
import '../../util/app_routes.dart';
import 'driver_registration_screen.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  _DriverListScreenState createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  late DriverController _driverController;
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool isDeleteSuccess = false;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Load customers when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _driverController = Provider.of<DriverController>(context, listen: false);
      _driverController.getDriverData().then((_) {
        setState(() {
          _isInitialLoad = false; // Set to false after initial load
        });
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
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

  void _deleteDriver(int index) {
    final driverId = _driverController.driverData?[index]['id'];
    print('driverid $driverId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Driver"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to delete this driver?"),

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
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  if (driverId != null) {
                    await _driverController.deleteDriver(driverId, reason);
                  }
                  Navigator.pop(context);
                  showSuccessSnack("Customer Deleted successfully");
                } else {
                  showErrorSnack("Please enter a reason for deletion");
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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

  void _navigateTodriverDetails(Map<String, dynamic> driver) async {
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
    final driverController = Provider.of<DriverController>(context);
    final watch = context.watch<DriverController>();
    final drivers =
        watch.driverData != null
            ? (watch.driverData ?? [])
                .where(
                  (driver) => (driver['Name'] ?? '').toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList()
            : [];
    return Consumer<DriverController>(
      builder: (context, driverController, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Drivers List')),
          body:
              watch.isLoading && _isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.driverData != null
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
                              drivers.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No drivers registered yet.'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    // padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: drivers.length,
                                    itemBuilder: (context, index) {
                                      final driver = drivers[index];
                                      return GestureDetector(
                                        onTap: () {
                                          _navigateTodriverDetails(
                                            drivers[index],
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            ListTile(
                                              // contentPadding: EdgeInsets.all(
                                              //   8.0,
                                              // ),
                                              leading: Icon(
                                                Icons.person,
                                                size: 30,
                                              ),
                                              title: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 2,
                                                ),
                                                child: Text(
                                                  driver['Name'] ?? '',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              trailing:
                                                  AuthRepo.role == "customer" ||
                                                          AuthRepo.role ==
                                                              "operator"
                                                      ? SizedBox.shrink()
                                                      : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            onPressed: () {
                                                              NavigationService()
                                                                  .pushNavigation(
                                                                    Screenroutes
                                                                        .driverEdit,
                                                                    arguments:
                                                                        driver,
                                                                  );
                                                            },

                                                            icon: Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          IconButton(
                                                            onPressed:
                                                                () async {
                                                                  _deleteDriver(
                                                                    index,
                                                                  );
                                                                },
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                  ),
                                              child: Divider(
                                                color: Colors.grey,
                                                thickness: .5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
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
                          builder: (context) => DriverRegistrationScreen(),
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
