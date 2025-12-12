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
  @override
  void initState() {
    super.initState();
    // ✅ FIXED: Clear data first, then fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<FuelTripController>();
      // Clear old data immediately
      controller.clearAcceptedAssignment();
      // Then fetch new data
      controller.getAcceptedAssignments();
    });
  }

  // ... rest of your methods remain the same ...

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
                        'Required',
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
                  'Arrival Time: ${stop['arrival_time']}',
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
          '${quantity.toStringAsFixed(2)} L',
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
      appBar: AppBar(title: const Text('Accepted Assignments'), elevation: 0),
      body: Consumer<FuelTripController>(
        builder: (context, controller, child) {
          // ✅ FIXED: Show loading ALWAYS when loading, even if old data exists
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

          // Show empty state only when not loading and no data
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
                    'You have no active assignments',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.getAcceptedAssignments();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final assignment = controller.acceptedAssignmentData!;
          final tripStops = assignment['trip_stops'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: () => controller.getAcceptedAssignments(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Section
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
                                    'Active Assignment',
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

                  // Assignment Details Card
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
                              'Assignment Details',
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
                              'Current Fuel Status',
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
                                    'Available in Vehicle:',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    '${_toDouble(assignment['available_qty']).toStringAsFixed(2)} L',
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

                  // Trip Stops Section
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

    final isCompleted =
        stop['status'] == 'completed' || stop['is_completed'] == true;

    bool isPreviousCompleted = true;
    if (index > 0) {
      final tripStops = assignment['trip_stops'] as List<dynamic>;
      final previousStop = tripStops[index - 1];
      isPreviousCompleted =
          previousStop['status'] == 'completed' ||
          previousStop['is_completed'] == true;
    }

    final isEnabled = isPreviousCompleted && !isCompleted;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            isEnabled
                ? () => _handleStopSelection(context, assignment, stop, index)
                : null,
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stop ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!isEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            hasEnoughFuel
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasEnoughFuel ? Icons.check_circle : Icons.warning,
                            size: 16,
                            color: hasEnoughFuel ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasEnoughFuel ? 'Ready' : 'Refill',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  hasEnoughFuel ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop['customer_name'],
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
                    'Required: ${expectedQty.toStringAsFixed(2)} L',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
                    'Arrival: ${stop['arrival_time']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
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
                            ? 'Completed'
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
