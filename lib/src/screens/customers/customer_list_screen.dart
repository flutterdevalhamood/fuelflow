import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/snack.dart';

import '../../providers/customer_controller.dart';
import '../../util/app_navigation.dart';
import '../../util/app_routes.dart';
import 'customer_registration_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  late CustomerController _customerController;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool isDeleteSuccess = false;
  bool _isInitialLoad = true;

  // Track which card is expanded
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    // Load customers when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _customerController = Provider.of<CustomerController>(
        context,
        listen: false,
      );
      _customerController.getCustomerData().then((_) {
        setState(() {
          _isInitialLoad = false;
        });
      });
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_customerController.isLoading && _customerController.hasMore) {
          _customerController.loadMore();
          showInfoSnack('Loading...');
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _deleteCustomer(int index) {
    final customerId = _customerController.customerData?[index]['id'];
    print('customerid $customerId');
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
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  if (customerId != null) {
                    await _customerController.deleteCustomer(
                      customerId,
                      reason,
                    );
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

  void _navigateTocustomerDetails(Map<String, dynamic> customer) async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.customerDetail,
      arguments: customer,
    );
    if (result == true) {
      final customerController = Provider.of<CustomerController>(
        context,
        listen: false,
      );
      customerController.getCustomerData();
    }
  }

  void _navigateToMyVehicles(Map<String, dynamic> customer) async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.myVehicles,
      arguments: customer,
    );
    if (result == true) {
      final customerController = Provider.of<CustomerController>(
        context,
        listen: false,
      );
      customerController.getCustomerData();
    }
  }

  void _navigateToMyDrivers(Map<String, dynamic> customer) async {
    final result = await NavigationService().pushNavigation(
      Screenroutes.myDrivers,
      arguments: customer,
    );
    if (result == true) {
      final customerController = Provider.of<CustomerController>(
        context,
        listen: false,
      );
      customerController.getCustomerData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerController = Provider.of<CustomerController>(context);
    final watch = context.watch<CustomerController>();
    final customers =
        watch.customerData != null
            ? (watch.customerData ?? [])
                .where(
                  (customer) =>
                      (customer['Name'] ?? '').toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (customer['representative'] ?? '').toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList()
            : [];
    return Consumer<CustomerController>(
      builder: (context, customerController, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Customer List')),
          body:
              watch.isLoading && _isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.customerData != null
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
                              hintText:
                                  'Search by company or representative...',
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
                              customers.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No customers registered yet.'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    itemCount: customers.length,
                                    itemBuilder: (context, index) {
                                      final customer = customers[index];
                                      final isExpanded =
                                          _expandedIndex == index;
                                      return Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _navigateTocustomerDetails(
                                                customers[index],
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 4,
                                                  ),
                                              child: Card(
                                                elevation: 4.0,
                                                margin: EdgeInsets.symmetric(
                                                  horizontal:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 24.0
                                                          : 12.0,
                                                  vertical: 4.0,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          10.0,
                                                        ),
                                                        bottom: Radius.circular(
                                                          isExpanded ? 0 : 10.0,
                                                        ),
                                                      ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      contentPadding:
                                                          EdgeInsets.all(16.0),
                                                      leading: Icon(
                                                        Icons.person,
                                                        size: 30,
                                                      ),
                                                      title: Text(
                                                        customer['Name'] ?? '',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      subtitle: Text(
                                                        'Rep: ${(customer['representative'] ?? '')}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium!
                                                            .copyWith(
                                                              color:
                                                                  Appcolors.textLightGrayColor(
                                                                    context,
                                                                  ),
                                                            ),
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            onPressed: () {
                                                              NavigationService()
                                                                  .pushNavigation(
                                                                    Screenroutes
                                                                        .customerEdit,
                                                                    arguments:
                                                                        customer,
                                                                  );
                                                            },
                                                            icon: Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                          ),
                                                          // SizedBox(width: 8),
                                                          IconButton(
                                                            onPressed: () async {
                                                              _deleteCustomer(
                                                                index,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                if (isExpanded) {
                                                                  _expandedIndex =
                                                                      null; // Collapse
                                                                } else {
                                                                  _expandedIndex =
                                                                      index; // Expand
                                                                }
                                                              });
                                                            },
                                                            icon: Icon(
                                                              isExpanded
                                                                  ? Icons
                                                                      .arrow_drop_up
                                                                  : Icons
                                                                      .arrow_drop_down,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isExpanded)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 16.0,
                                                              right: 16.0,
                                                              bottom: 16.0,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            Divider(
                                                              thickness: 1,
                                                              color:
                                                                  Colors
                                                                      .grey[300],
                                                            ),
                                                            SizedBox(height: 8),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    _navigateToMyVehicles(
                                                                      customers[index],
                                                                    );
                                                                    print(
                                                                      'My Vehicles selected',
                                                                    );
                                                                  },
                                                                  child: Text(
                                                                    'My Vehicles',
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .blue,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                GestureDetector(
                                                                  onTap: () {
                                                                    _navigateToMyDrivers(
                                                                      customer,
                                                                    );
                                                                  },

                                                                  child: Text(
                                                                    'My Drivers',
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .blue,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
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
                                              ),
                                            ),
                                          ),
                                          // Attached curved border for expanded section
                                          if (isExpanded)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Card(
                                                elevation: 4.0,
                                                margin: EdgeInsets.only(
                                                  bottom: 16.0,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                          10.0,
                                                        ),
                                                      ),
                                                ),
                                                child: Container(
                                                  height:
                                                      0, // No height, just for border
                                                ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRegistrationScreen(),
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
