import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/screens/fuelTrip/trip_start_screen.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class AcceptedAssignmentScreen extends StatefulWidget {
  final int driverId;

  const AcceptedAssignmentScreen({super.key, required this.driverId});

  @override
  State<AcceptedAssignmentScreen> createState() =>
      _AcceptedAssignmentScreenState();
}

class _AcceptedAssignmentScreenState extends State<AcceptedAssignmentScreen>
    with RouteAware {
  // Track which stop card is expanded
  int? _expandedStopIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAssignments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Subscribe to route observer
    final route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      Screenroutes.routeobserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // ✅ Unsubscribe from route observer
    Screenroutes.routeobserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // ✅ Called when returning to this screen from another screen
    debugPrint('🔄 AcceptedAssignmentScreen became visible - auto-refreshing');
    _refreshAssignments();
  }

  Future<void> _refreshAssignments() async {
    final controller = context.read<FuelTripController>();

    await controller.getAcceptedAssignments();
  }

  // Replace the existing method with this:
  Map<String, dynamic> _calculateTotalRequirements(
    Map<String, dynamic> assignment,
    List<dynamic> tripStops,
  ) {
    double totalRequired = 0.0;
    double availableQty = _toDouble(assignment['available_qty']);

    // Sum up required quantities for all incomplete stops
    for (var stop in tripStops) {
      final status = stop['status']?.toString().toLowerCase() ?? '';
      final isCompleted = status == 'delivered' || status == 'completed';

      if (!isCompleted) {
        totalRequired +=
            double.tryParse(stop['expected_qty'].toString()) ?? 0.0;
      }
    }

    double deficit = totalRequired - availableQty;

    return {
      'totalRequired': totalRequired,
      'availableQty': availableQty,
      'deficit': deficit > 0 ? deficit : 0.0,
      'hasDeficit':
          deficit > 0, // This is now allowed because return type is dynamic
    };
  }

  bool _isStopDelivered(Map<String, dynamic> stop) {
    final stopVehicles = stop['stop_vehicles'] as List<dynamic>? ?? [];

    if (stopVehicles.isEmpty) {
      final status = stop['status']?.toString().toLowerCase() ?? '';
      return status == 'delivered' || status == 'completed';
    }

    bool allVehiclesProcessed = stopVehicles.every((vehicle) {
      final statusValue =
          int.tryParse(vehicle['status']?.toString() ?? '0') ?? 0;
      return statusValue != 0; // Not pending
    });

    return allVehiclesProcessed;
  }

  void _handleStopSelection(
    BuildContext context,
    Map<String, dynamic> assignment,
    Map<String, dynamic> stop,
    int stopIndex,
  ) {
    final requiredQty = double.tryParse(stop['expected_qty'].toString()) ?? 0.0;
    final availableQty = _toDouble(assignment['available_qty']);

    final tripStops = assignment['trip_stops'] as List<dynamic>? ?? [];
    final totalStops = tripStops.length;

    // Removed the completed stop check - directly proceed with fuel check
    if (availableQty < requiredQty) {
      _showRefillDialog(
        context,
        assignment,
        stop,
        requiredQty,
        availableQty,
        stopIndex,
        totalStops,
      );
    } else {
      _showStartTripDialog(context, assignment, stop, stopIndex, totalStops);
    }
  }

  void _showRefillDialog(
    BuildContext context,
    Map<String, dynamic> assignment,
    Map<String, dynamic> stop,
    double requiredQty,
    double availableQty,
    int stopIndex,
    int totalStops,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Refill Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Insufficient Fuel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildQuantityRow('Required', requiredQty, Colors.red),
                      const SizedBox(height: 8),
                      _buildQuantityRow(
                        'Available',
                        availableQty,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildQuantityRow(
                        'Deficit',
                        requiredQty - availableQty,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You need to refill fuel from the depot tank before starting this trip.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  final result = await NavigationService().pushNavigation(
                    Screenroutes.fuelRefillBeforeTripScreen,
                    arguments: {
                      'assignmentId': assignment['assignment_id'] ?? 0,
                      'vehicleId': assignment['vehicle_id'] ?? 0,
                      'tripId': assignment['trip_id'] ?? '',
                      'tripStopId': stop['stop_id'] ?? 0,
                      'requiredQty': requiredQty,
                      'availableQty': availableQty,
                      'vehicleName': assignment['vehicle'] ?? 'Unknown Vehicle',
                      'stopOrder': stop['stop_order'] ?? '1',
                      'customerName': stop['customer_name'] ?? '',
                    },
                  );

                  // ✅ Auto-refresh if refill was completed successfully
                  if (result == true && mounted) {
                    debugPrint('🔄 Auto-refreshing after successful refill...');
                    await _refreshAssignments();

                    // Show success feedback
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fuel quantities updated successfully!',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.local_gas_station),
                label: const Text('Go to Refill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // void _showRefillDialog(
  //   BuildContext context,
  //   Map<String, dynamic> assignment,
  //   Map<String, dynamic> stop,
  //   double requiredQty,
  //   double availableQty,
  //   int stopIndex,
  //   int totalStops,
  // ) {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (dialogContext) => AlertDialog(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(16),
  //           ),
  //           title: Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: Colors.orange.shade50,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Icon(
  //                   Icons.local_gas_station,
  //                   color: Colors.orange.shade700,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               const Text('Refill Required'),
  //             ],
  //           ),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red.shade50,
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(color: Colors.red.shade200),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Row(
  //                       children: [
  //                         const Icon(
  //                           Icons.warning_amber_rounded,
  //                           color: Colors.red,
  //                           size: 24,
  //                         ),
  //                         const SizedBox(width: 12),
  //                         const Expanded(
  //                           child: Text(
  //                             'Insufficient Fuel',
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.bold,
  //                               fontSize: 16,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 12),
  //                     _buildQuantityRow('Required', requiredQty, Colors.red),
  //                     const SizedBox(height: 8),
  //                     _buildQuantityRow(
  //                       'Available',
  //                       availableQty,
  //                       Colors.orange,
  //                     ),
  //                     const SizedBox(height: 8),
  //                     _buildQuantityRow(
  //                       'Deficit',
  //                       requiredQty - availableQty,
  //                       Colors.red,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               const Text(
  //                 'You need to refill fuel from the depot tank before starting this trip.',
  //                 style: TextStyle(fontSize: 14, color: Colors.grey),
  //               ),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(dialogContext).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton.icon(
  //               onPressed: () {
  //                 Navigator.of(dialogContext).pop();
  //                 NavigationService().pushNavigation(
  //                   Screenroutes.fuelRefillBeforeTripScreen,
  //                   arguments: {
  //                     'assignmentId': assignment['assignment_id'] ?? 0,
  //                     'vehicleId': assignment['vehicle_id'] ?? 0,
  //                     'tripId': assignment['trip_id'] ?? '',
  //                     'tripStopId': stop['stop_id'] ?? 0,
  //                     'requiredQty': requiredQty,
  //                     'availableQty': availableQty,
  //                     'vehicleName': assignment['vehicle'] ?? 'Unknown Vehicle',
  //                     'stopOrder': stop['stop_order'] ?? '1',
  //                     'customerName': stop['customer_name'] ?? '',
  //                   },
  //                 );
  //               },
  //               icon: const Icon(Icons.local_gas_station),
  //               label: const Text('Go to Refill'),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.orange,
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 20,
  //                   vertical: 12,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  void _showStartTripDialog(
    BuildContext context,
    Map<String, dynamic> assignment,
    Map<String, dynamic> stop,
    int stopIndex,
    int totalStops,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                const Text('Ready to Start'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Sufficient Fuel Available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildQuantityRow(
                        'Customer Req.',
                        double.tryParse(stop['expected_qty'].toString()) ?? 0,
                        Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      _buildQuantityRow(
                        'Available',
                        _toDouble(assignment['available_qty']),
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Customer: ${stop['customer_name']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stop ${stopIndex + 1} of $totalStops',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrival Time: ${stop['expected_arrival_time'] ?? 'Not Set'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TripStartedScreen(
                            tripId:
                                int.tryParse(
                                  assignment['trip_id'].toString(),
                                ) ??
                                0,
                            tripStopId: int.tryParse(
                              stop['stop_id'].toString(),
                            ),
                            customerName: stop['customer_name'] ?? 'Unknown',
                            arrivalTime: stop['arrival_time'] ?? 'N/A',
                            assignmentId: assignment['assignment_id'] ?? 0,
                            vehicleId: assignment['vehicle_id'] ?? 0,
                            requiredQty:
                                double.tryParse(
                                  stop['expected_qty'].toString(),
                                ) ??
                                0.0,
                            availableQty: _toDouble(
                              assignment['available_qty'],
                            ),
                            vehicleName:
                                assignment['vehicle'] ?? 'Unknown Vehicle',
                            stopOrder: stop['stop_order'] ?? '1',
                            currentStopIndex: stopIndex,
                            totalStops: totalStops,
                            driverId: assignment['driver_id'] ?? 0,
                            siteName: stop['site_name'],
                            stopVehicles:
                                stop['stop_vehicles'] as List<dynamic>?,
                          ),
                    ),
                  );

                  // If stop was completed, refresh the assignments
                  if (result == true && mounted) {
                    debugPrint(
                      '🔄 Refreshing assignments after stop completion...',
                    );
                    await _refreshAssignments();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stop marked as delivered!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Add these methods to _AcceptedAssignmentScreenState class

  void _handleVehicleRefuel(
    BuildContext context,
    Map<String, dynamic> assignment,
    Map<String, dynamic> stop,
    int vehicleId,
    String plateNo,
  ) async {
    final requiredQty = double.tryParse(stop['expected_qty'].toString()) ?? 0.0;
    final availableQty = _toDouble(assignment['available_qty']);

    // Navigate to refill screen
    final result = await NavigationService().pushNavigation(
      Screenroutes.fuelRefillBeforeTripScreen,
      arguments: {
        'assignmentId':
            int.tryParse(assignment['assignment_id']?.toString() ?? '0') ?? 0,
        'vehicleId': vehicleId,
        'tripId': assignment['trip_id']?.toString() ?? '',
        'tripStopId': int.tryParse(stop['stop_id']?.toString() ?? '0') ?? 0,
        'requiredQty': requiredQty,
        'availableQty': availableQty,
        'vehicleName': plateNo,
        'stopOrder': stop['stop_order'] ?? '1',
        'customerName': stop['customer_name'] ?? '',
      },
    );

    // Refresh if refill was completed
    if (result == true && mounted) {
      debugPrint('🔄 Auto-refreshing after vehicle refill...');
      await _refreshAssignments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle refueled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // void _handleVehicleUnavailable(
  //   BuildContext context,
  //   Map<String, dynamic> assignment,
  //   Map<String, dynamic> stop,
  //   int vehicleId,
  //   String plateNo,
  // ) async {
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => BulkVehicleUnavailableScreen(
  //             vehicleId: vehicleId,
  //             plateNo: plateNo,
  //             tripStopId: int.tryParse(stop['stop_id']?.toString() ?? '0') ?? 0,
  //             customerName: stop['customer_name']?.toString() ?? 'Unknown',
  //             siteName: stop['site_name']?.toString() ?? 'Unknown',
  //           ),
  //     ),
  //   );
  //
  //   // Refresh if vehicle was marked unavailable
  //   if (result == true && mounted) {
  //     debugPrint('🔄 Auto-refreshing after marking vehicle unavailable...');
  //     await _refreshAssignments();
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Vehicle $plateNo marked as unavailable'),
  //           backgroundColor: Colors.orange,
  //           duration: const Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   }
  // }

  Widget _buildQuantityRow(String label, double quantity, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          '${quantity.toStringAsFixed(2)} IG',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
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
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     NavigationService().pushNavigation(Screenroutes.dashboard);
        //   },
        // ),
        title: const Text('Accepted Trips'),
        elevation: 0,
      ),
      body: Consumer<FuelTripController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading accepted assignments...',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (controller.acceptedAssignmentData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Accepted Assignments',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have no active trips',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _refreshAssignments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final assignment = controller.acceptedAssignmentData!;
          final tripStops = assignment['trip_stops'] as List<dynamic>? ?? [];

          // Calculate total requirements
          final totals = _calculateTotalRequirements(assignment, tripStops);

          return RefreshIndicator(
            onRefresh: _refreshAssignments,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Trip',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trip ID: ${assignment['trip_id']}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // const Text(
                            //   'Trip Details',
                            //   style: TextStyle(
                            //     fontSize: 18,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            // const SizedBox(height: 16),
                            // _buildDetailRow(
                            //   Icons.directions_car,
                            //   'Vehicle',
                            //   assignment['vehicle'],
                            //   Colors.green,
                            // ),
                            // const SizedBox(height: 12),
                            // _buildDetailRow(
                            //   Icons.person,
                            //   'Driver',
                            //   assignment['driver'],
                            //   Colors.purple,
                            // ),
                            // const SizedBox(height: 16),
                            // const Divider(),
                            // const SizedBox(height: 16),
                            // const Text(
                            //   'Current Available Fuel Stock',
                            //   style: TextStyle(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Rem. Stock in Vehicle:',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    '${_toDouble(assignment['available_qty']).toStringAsFixed(2)} IG',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overall Refill Status Card
                  if (totals['hasDeficit'] == true) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Overall Refill Required',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildQuantityRow(
                                    'Total Req. (All Stops)',
                                    totals['totalRequired']!,
                                    Colors.grey.shade700,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildQuantityRow(
                                    'Currently Available',
                                    totals['availableQty']!,
                                    Colors.blue,
                                  ),
                                  const Divider(height: 20),
                                  _buildQuantityRow(
                                    'Total Deficit',
                                    totals['deficit']!,
                                    Colors.orange.shade900,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'You need to refill ${totals['deficit']!.toStringAsFixed(2)} IG from the depot to complete all remaining stops.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery Stops (${tripStops.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (tripStops.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No stops available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tripStops.length,
                            itemBuilder: (context, index) {
                              // Sort stops: incomplete first, completed last
                              final sortedStops = List<
                                Map<String, dynamic>
                              >.from(
                                tripStops.map((e) => e as Map<String, dynamic>),
                              )..sort((a, b) {
                                // ✅ Use the helper method for sorting
                                final aCompleted = _isStopDelivered(a);
                                final bCompleted = _isStopDelivered(b);

                                // Incomplete stops come first
                                if (!aCompleted && bCompleted) return -1;
                                if (aCompleted && !bCompleted) return 1;

                                // Within same completion status, maintain original order
                                final aOrder =
                                    int.tryParse(
                                      a['stop_order']?.toString() ?? '0',
                                    ) ??
                                    0;
                                final bOrder =
                                    int.tryParse(
                                      b['stop_order']?.toString() ?? '0',
                                    ) ??
                                    0;
                                return aOrder.compareTo(bOrder);
                              });

                              final stop = sortedStops[index];
                              return _buildStopCard(
                                context,
                                assignment,
                                stop,
                                index,
                                tripStops.length,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopCard(
    BuildContext context,
    Map<String, dynamic> assignment,
    Map<String, dynamic> stop,
    int index,
    int totalStops,
  ) {
    final expectedQty = double.tryParse(stop['expected_qty'].toString()) ?? 0.0;
    final availableQty = _toDouble(assignment['available_qty']);
    final hasEnoughFuel = availableQty >= expectedQty;

    // ✅ Use the new helper method instead of just checking backend status
    final isCompleted = _isStopDelivered(stop);

    // Find the original index in the unsorted list for "previous stop" check
    final tripStops = assignment['trip_stops'] as List<dynamic>;
    final originalIndex = tripStops.indexOf(stop);

    bool isPreviousCompleted = true;
    if (originalIndex > 0) {
      final previousStop = tripStops[originalIndex - 1];
      // ✅ Also use helper method for previous stop
      isPreviousCompleted = _isStopDelivered(previousStop);
    }

    final isEnabled = isPreviousCompleted && !isCompleted;

    // Get vehicles list from stop_vehicles
    final stopVehicles = stop['stop_vehicles'] as List<dynamic>? ?? [];
    final isExpanded = _expandedStopIndex == index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Card Content
        Card(
          elevation: isCompleted ? 4 : 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isCompleted
                    ? BorderSide(color: Colors.green.shade300, width: 2)
                    : BorderSide.none,
          ),
          child: Stack(
            children: [
              InkWell(
                onTap:
                    isEnabled
                        ? () => _handleStopSelection(
                          context,
                          assignment,
                          stop,
                          index,
                        )
                        : null,
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: isCompleted ? 0.7 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isCompleted
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Stop ${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isCompleted
                                          ? Colors.green.shade900
                                          : Colors.blue.shade900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (stop['status'] != null &&
                                stop['status'].toString().isNotEmpty &&
                                !isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  stop['status'].toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${assignment['customer_name'] ?? 'Unknown Customer'}'
                                ' - '
                                '${stop['site_name'] ?? 'Unknown Site'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.local_gas_station,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Requirement: ${expectedQty.toStringAsFixed(2)} IG',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Arrival: ${stop['expected_arrival_time'] ?? 'Not Set'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),

                        if (stopVehicles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              // Navigate to VehicleListScreen using proper route
                              final result = await NavigationService()
                                  .pushNavigation(
                                    Screenroutes.stopVehicleListScreen,
                                    arguments: {
                                      'stopVehicles': stopVehicles,
                                      'assignment': assignment,
                                      'stop': stop,
                                      'customerName':
                                          assignment['customer_name'] ??
                                          'Unknown Customer',
                                      'siteName':
                                          stop['site_name'] ?? 'Unknown Site',
                                    },
                                  );

                              // Refresh if any action was completed on vehicles
                              if (result == true && mounted) {
                                debugPrint(
                                  '🔄 Auto-refreshing after vehicle action...',
                                );
                                await _refreshAssignments();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vehicles updated successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black87,
                                    Colors.purple.shade500,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade200,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'View Vehicles',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${stopVehicles.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Replace the vehicle list section in _buildStopCard with this:
                        // Expanded Vehicle List with Actions
                        if (isExpanded && stopVehicles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vehicle Plate Numbers:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Replace the vehicle status determination section in _buildStopCard
                                // Starting from line ~1140 in your code
                                ...stopVehicles.map((vehicleData) {
                                  final plateNo =
                                      vehicleData['plate_no']?.toString() ??
                                      'N/A';
                                  final vehicleId =
                                      int.tryParse(
                                        vehicleData['vehicle_id']?.toString() ??
                                            '0',
                                      ) ??
                                      0;

                                  // Parse status as integer
                                  final statusValue =
                                      int.tryParse(
                                        vehicleData['status']?.toString() ??
                                            '0',
                                      ) ??
                                      0;

                                  // Determine vehicle state based on status
                                  final isUnavailable = statusValue == -1;
                                  final isPending = statusValue == 0;
                                  final isCompleted = statusValue == 1;

                                  // Determine colors and labels based on status
                                  Color borderColor;
                                  Color bgColor;
                                  Color iconColor;
                                  Color containerBgColor;
                                  Color containerBorderColor;
                                  String? statusLabel;

                                  if (isUnavailable) {
                                    borderColor = Colors.red.shade300;
                                    bgColor = Colors.red.shade50;
                                    iconColor = Colors.red.shade700;
                                    containerBgColor = Colors.red.shade100;
                                    containerBorderColor = Colors.red.shade400;
                                    statusLabel = 'Unavailable';
                                  } else if (isCompleted) {
                                    borderColor = Colors.green.shade300;
                                    bgColor = Colors.green.shade50;
                                    iconColor = Colors.green.shade700;
                                    containerBgColor = Colors.green.shade100;
                                    containerBorderColor =
                                        Colors.green.shade400;
                                    statusLabel = 'Completed';
                                  } else {
                                    // Pending (status = 0)
                                    borderColor = Colors.amber.shade400;
                                    bgColor = Colors.amber.shade50;
                                    iconColor = Colors.amber.shade700;
                                    containerBgColor = Colors.amber.shade100;
                                    containerBorderColor =
                                        Colors.amber.shade400;
                                    statusLabel = 'Pending';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: borderColor,
                                          width:
                                              2, // Keep width 2 for all statuses for consistency
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: containerBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: containerBorderColor,
                                              ),
                                            ),
                                            child: Icon(
                                              isCompleted
                                                  ? Icons.check_circle
                                                  : isPending
                                                  ? Icons.pending
                                                  : Icons.directions_car,
                                              size: 16,
                                              color: iconColor,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  plateNo,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isUnavailable
                                                            ? Colors
                                                                .red
                                                                .shade700
                                                            : isCompleted
                                                            ? Colors
                                                                .green
                                                                .shade700
                                                            : Colors
                                                                .amber
                                                                .shade900,
                                                  ),
                                                ),
                                                if (statusLabel != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    statusLabel,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isUnavailable
                                                              ? Colors
                                                                  .red
                                                                  .shade600
                                                              : isCompleted
                                                              ? Colors
                                                                  .green
                                                                  .shade600
                                                              : Colors
                                                                  .amber
                                                                  .shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          // Show action buttons only for pending vehicles
                                          if (isPending) ...[
                                            // Refuel Icon
                                            IconButton(
                                              onPressed:
                                                  () => _handleVehicleRefuel(
                                                    context,
                                                    assignment,
                                                    stop,
                                                    vehicleId,
                                                    plateNo,
                                                  ),
                                              icon: const Icon(
                                                Icons.local_gas_station,
                                              ),
                                              color: Colors.orange,
                                              tooltip: 'Refuel Vehicle',
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange.shade50,
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Make Unavailable Icon
                                            // IconButton(
                                            //   onPressed:
                                            //       () =>
                                            //           _handleVehicleUnavailable(
                                            //             context,
                                            //             assignment,
                                            //             stop,
                                            //             vehicleId,
                                            //             plateNo,
                                            //           ),
                                            //   icon: const Icon(Icons.block),
                                            //   color: Colors.red,
                                            //   tooltip: 'Mark Unavailable',
                                            //   style: IconButton.styleFrom(
                                            //     backgroundColor:
                                            //         Colors.red.shade50,
                                            //     padding: const EdgeInsets.all(
                                            //       8,
                                            //     ),
                                            //   ),
                                            // ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    isEnabled
                                        ? () => _handleStopSelection(
                                          context,
                                          assignment,
                                          stop,
                                          index,
                                        )
                                        : null,
                                icon: Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : !isEnabled
                                      ? Icons.lock
                                      : hasEnoughFuel
                                      ? Icons.play_arrow
                                      : Icons.local_gas_station,
                                  size: 18,
                                ),
                                label: Text(
                                  isCompleted
                                      ? 'Delivered'
                                      : !isEnabled
                                      ? 'Complete Previous Stop First'
                                      : hasEnoughFuel
                                      ? 'Start Journey'
                                      : 'Refill First',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isCompleted
                                          ? Colors.green
                                          : !isEnabled
                                          ? Colors.grey
                                          : hasEnoughFuel
                                          ? Colors.green
                                          : Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ✅ DELIVERED Stamp Overlay
              if (isCompleted)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: Text(
                          'DELIVERED',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade700,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
