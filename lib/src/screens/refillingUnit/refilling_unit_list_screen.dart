import 'dart:async';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/refillingUnit/refilling_unit_registration_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_colors.dart';

class RefillingUnitListScreen extends StatefulWidget {
  const RefillingUnitListScreen({super.key});

  @override
  State<RefillingUnitListScreen> createState() =>
      _RefillingUnitListScreenState();
}

class _RefillingUnitListScreenState extends State<RefillingUnitListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool confirmLogout = false;
  late RefillingUnitController _fuelRefillingUnitController;
  final ScrollController _scrollController = ScrollController();
  bool isInitialLoad = true;
  int? _selectedCustomerId;
  final TextEditingController _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _fuelRefillingUnitController = Provider.of<RefillingUnitController>(
        context,
        listen: false,
      );
      _fuelRefillingUnitController.getRefillUnitData().then((_) {
        setState(() {
          isInitialLoad = false;
        });
      });
      _fuelRefillingUnitController.getFuelRefillDropdown();
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_fuelRefillingUnitController.isLoading &&
            _fuelRefillingUnitController.hasMore) {
          _fuelRefillingUnitController.loadMore();
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

  // void _deleteRefillUnitData(int index) {
  //   final refillUnitId =
  //       _fuelRefillingUnitController.refillUnitData?[index]['id'];
  //
  //   print('refillUnitId $refillUnitId');
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Delete Refill Unit Data"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min, // To make the dialog compact
  //           children: [
  //             Text("Are you sure you want to delete this refill Unit?"),
  //             SizedBox(height: 16), // Add some spacing
  //             TextField(
  //               controller: _reasonController,
  //               decoration: InputDecoration(
  //                 labelText: 'Reason for deletion',
  //                 border: OutlineInputBorder(),
  //               ),
  //               maxLines: 3, // Allow multiple lines for the reason
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context), // Cancel
  //             child: Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               String reason = _reasonController.text.trim();
  //               print('reasonfordelete $reason');
  //               if (reason.isNotEmpty) {
  //                 if (refillUnitId != null) {
  //                   await _fuelRefillingUnitController.deleteRefillUnitData(
  //                     refillUnitId,
  //                     _reasonController.text.trim(),
  //                   );
  //                 }
  //                 print("Deleting RefillUnitData with reason: $reason");
  //                 Navigator.pop(context);
  //                 showSuccessSnack('RefillUnitData Deleted Successfully');
  //               } else {
  //                 // Show an error or prompt the user to enter a reason
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                     content: Text("Please enter a reason for deletion"),
  //                   ),
  //                 );
  //               }
  //             },
  //             child: Text("Delete", style: TextStyle(color: Colors.red)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _refillDetails(Map<String, dynamic> refillUnitData) {
    final result = NavigationService().pushNavigation(
      Screenroutes.refillingUnitDetailScreen,
      arguments: refillUnitData,
    );
    if (result == true) {
      _fuelRefillingUnitController.getRefillUnitData();
    }
  }

  void _assignCustomer(
    Map<String, dynamic> refillUnit,
    List<Map<String, dynamic>>? customerData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Assign Customer"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select a customer to assign to this refilling unit:"),
                  SizedBox(height: 16),
                  DropdownSearch<Map<String, dynamic>>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.tight,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search Customer Name...',
                        ),
                      ),
                    ),
                    items: (filter, infiniteScrollProps) => customerData ?? [],
                    itemAsString: (item) => item['Name'] ?? '',
                    compareFn: (
                      Map<String, dynamic> item1,
                      Map<String, dynamic> item2,
                    ) {
                      return item1['id'] ==
                          item2['id']; // Compare items by their ID
                    },
                    onChanged: (Map<String, dynamic>? newValue) async {
                      if (newValue != null) {
                        setState(() {
                          _selectedCustomerId = newValue['id'];
                          _customerController.text = newValue['Name'];
                        });
                      }
                    },
                    selectedItem:
                        _selectedCustomerId != null
                            ? customerData?.firstWhere(
                              (customer) =>
                                  customer['id'] == _selectedCustomerId,
                              orElse: () => <String, dynamic>{},
                            )
                            : null,
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a Customer Name';
                      }
                      return null;
                    },
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                      ),
                    ),
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
                    if (_selectedCustomerId != null) {
                      bool isSuccess = await _fuelRefillingUnitController
                          .assignRefillingUnit(
                            refillUnit['id'],
                            _selectedCustomerId!,
                          );
                      Navigator.pop(context);
                      if (isSuccess) {
                        showSuccessSnack('Customer assigned successfully');
                      } else {
                        showErrorSnack('Error Assigning Customer');
                      }
                    } else {
                      showErrorSnack('Please select a customer');
                    }
                  },
                  child: Text("Assign", style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _releaseCustomer(Map<String, dynamic> refillUnit) {
    final TextEditingController _descriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Release Customer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to release ${refillUnit['assigned_customer']?['Name']} from this refilling unit?",
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Reason for Release',
                  hintText: 'Enter the reason for releasing this customer',
                  hintStyle: TextStyle(color: Appcolors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
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
                if (_descriptionController.text.trim().isEmpty) {
                  showErrorSnack('Please enter a reason for release');
                  return;
                }

                // Call the controller method to release the customer with description
                bool isSuccess = await _fuelRefillingUnitController
                    .releaseRefillingUnit(
                      refillUnit['id'],
                      _descriptionController.text.trim(),
                    );
                Navigator.pop(context);
                if (isSuccess) {
                  showSuccessSnack('Customer released successfully');
                } else {
                  showErrorSnack('Error releasing Customer');
                }
              },
              child: Text("Release", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<RefillingUnitController>();

    final refillUnitData =
        watch.refillUnitData != null
            ? (watch.refillUnitData ?? [])
                .where(
                  (refillUnits) => (refillUnits['serial_no'] ?? '')
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
                )
                .toList()
            : [];
    print('refillUnitData $refillUnitData');
    return Consumer<RefillingUnitController>(
      builder: (context, refillUnitController, child) {
        final customerData = refillUnitController.customerData;
        print('customerdata $customerData');
        return Scaffold(
          appBar: AppBar(title: Text('Refilling Unit List')),
          body:
              watch.isLoading && isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.refillUnitData != null
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
                              hintText: 'Search by serial number',
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
                              refillUnitData.isEmpty
                                  ? Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? 'No Refilling Unit found'
                                          : 'No results found.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    itemCount: refillUnitData.length,
                                    itemBuilder: (context, index) {
                                      if (index == refillUnitData.length) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final refillUnit = refillUnitData[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          // Replace the existing ListTile with this updated version
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.local_gas_station,
                                                      size: 30,
                                                      color: Colors.blue,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        refillUnit['serial_no'] ??
                                                            'Unknown',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Show either Assign or Release icon based on assignment status
                                                        if (AuthRepo.role !=
                                                                "operator" &&
                                                            AuthRepo.role !=
                                                                "customer")
                                                          IconButton(
                                                            icon: Icon(
                                                              refillUnit['assigned_customer'] !=
                                                                      null
                                                                  ? Icons
                                                                      .link_off
                                                                  : Icons
                                                                      .assignment_add,
                                                              color:
                                                                  refillUnit['assigned_customer'] !=
                                                                          null
                                                                      ? Colors
                                                                          .red
                                                                      : Colors
                                                                          .green,
                                                            ),
                                                            tooltip:
                                                                refillUnit['assigned_customer'] !=
                                                                        null
                                                                    ? 'Release Customer'
                                                                    : 'Assign Customer',
                                                            onPressed: () {
                                                              if (refillUnit['assigned_customer'] !=
                                                                  null) {
                                                                // Handle releasing customer
                                                                _releaseCustomer(
                                                                  refillUnit,
                                                                );
                                                              } else {
                                                                // Handle assigning customer
                                                                _assignCustomer(
                                                                  refillUnit,
                                                                  customerData,
                                                                );
                                                              }
                                                            },
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
                                                                      .refillingUnitUpdateScreen,
                                                                  arguments:
                                                                      refillUnitData[index],
                                                                );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                // Assignment information in a styled container
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        refillUnit['assigned_customer'] !=
                                                                null
                                                            ? Colors.green
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : Colors.grey
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          refillUnit['assigned_customer'] !=
                                                                  null
                                                              ? Colors
                                                                  .green
                                                                  .shade200
                                                              : Colors
                                                                  .grey
                                                                  .shade300,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 16,
                                                        color:
                                                            refillUnit['assigned_customer'] !=
                                                                    null
                                                                ? Colors
                                                                    .green
                                                                    .shade700
                                                                : Colors
                                                                    .grey
                                                                    .shade600,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          refillUnit['assigned_customer'] !=
                                                                  null
                                                              ? "Assigned To: ${refillUnit['assigned_customer']?['Name']}"
                                                              : "Not Assigned",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                refillUnit['assigned_customer'] !=
                                                                        null
                                                                    ? Colors
                                                                        .green
                                                                        .shade700
                                                                    : Colors
                                                                        .grey
                                                                        .shade700,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
                  builder: (context) => RefillingUnitRegistrationScreen(),
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
