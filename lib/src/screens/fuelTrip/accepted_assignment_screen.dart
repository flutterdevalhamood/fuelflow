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

class _AcceptedAssignmentScreenState extends State<AcceptedAssignmentScreen> {
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

    final status = stop['status']?.toString().toLowerCase() ?? '';
    if (status == 'delivered' || status == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This stop has already been completed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  NavigationService().pushNavigation(
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
                        'Customer Requirement',
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(
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
                          ),
                    ),
                  );
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
      appBar: AppBar(title: const Text('Accepted Trips'), elevation: 0),
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
                            const Text(
                              'Trip Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.directions_car,
                              'Vehicle',
                              assignment['vehicle'],
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.person,
                              'Driver',
                              assignment['driver'],
                              Colors.purple,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Current Available Fuel Stock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                    'Total Required (All Stops)',
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
                              final stop = tripStops[index];
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

    final status = stop['status']?.toString().toLowerCase() ?? '';
    final isCompleted = status == 'delivered' || status == 'completed';

    bool isPreviousCompleted = true;
    if (index > 0) {
      final tripStops = assignment['trip_stops'] as List<dynamic>;
      final previousStop = tripStops[index - 1];
      final prevStatus = previousStop['status']?.toString().toLowerCase() ?? '';
      isPreviousCompleted =
          prevStatus == 'delivered' || prevStatus == 'completed';
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

                        // Vehicle Count Section
                        if (stopVehicles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedStopIndex = isExpanded ? null : index;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 20,
                                    color: Colors.purple.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vehicles',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${stopVehicles.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.purple.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Expanded Vehicle List
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
                                ...stopVehicles.map((vehicleData) {
                                  final vehicle =
                                      vehicleData['stop_vehicles']
                                          as Map<String, dynamic>? ??
                                      {};
                                  final plateNo = vehicle['plate_no'] ?? 'N/A';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.directions_car,
                                            size: 16,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            plateNo,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
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
