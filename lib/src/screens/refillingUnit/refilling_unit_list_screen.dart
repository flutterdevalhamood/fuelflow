import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
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
                                      return Dismissible(
                                        key: Key(
                                          refillUnit['serial_no'] ?? index,
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
                                          final refillUnitId =
                                              _fuelRefillingUnitController
                                                  .refillUnitData?[index]['id'];
                                          final reason =
                                              _reasonController.text.trim();
                                          watch.deleteRefillUnitData(
                                            refillUnitId,
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
                                                Icons.local_gas_station,
                                                size: 30,
                                                color: Colors.blue,
                                              ),
                                              title: Text(
                                                refillUnit['serial_no'] ??
                                                    'Unknown',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                refillUnit['code'] ??
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
                                                      await NavigationService()
                                                          .pushNavigation(
                                                            Screenroutes
                                                                .refillingUnitUpdateScreen,
                                                            arguments:
                                                                refillUnitData[index],
                                                          );
                                                    },
                                                  ),
                                                  // IconButton(
                                                  //   icon: Icon(
                                                  //     Icons.delete,
                                                  //     color: Colors.red,
                                                  //   ),
                                                  //   onPressed: () async {
                                                  //     _deleteRefillUnitData(
                                                  //       index,
                                                  //     );
                                                  //   },
                                                  // ),
                                                ],
                                              ),
                                              onTap:
                                                  () => _refillDetails(
                                                    refillUnit,
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
