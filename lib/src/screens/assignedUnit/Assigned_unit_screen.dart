import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/assigned_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';

class AssignedRefillingUnitScreen extends StatefulWidget {
  const AssignedRefillingUnitScreen({super.key});

  @override
  State<AssignedRefillingUnitScreen> createState() =>
      _AssignedRefillingUnitScreenState();
}

class _AssignedRefillingUnitScreenState
    extends State<AssignedRefillingUnitScreen> {
  bool isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<AssignedRefillingUnitController>(
        context,
        listen: false,
      );
      controller.customerId = AuthRepo.customerId;
      controller.getAssignedForCustomer().then((_) {
        setState(() {
          isInitialLoad = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Refilling Units'), elevation: 0),
      body: Consumer<AssignedRefillingUnitController>(
        builder: (context, controller, child) {
          if (controller.isLoading && isInitialLoad) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.assignedUnits == null ||
              controller.assignedUnits!.isEmpty) {
            return _buildNoUnitsView();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.getAssignedForCustomer();
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: controller.assignedUnits!.length,
                itemBuilder: (context, index) {
                  final unit = controller.assignedUnits![index];
                  return _buildUnitCard(unit);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoUnitsView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gas_meter_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No Refilling Units Assigned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You currently have no refilling units assigned to you.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final productName = unit['product']?['Name'] ?? 'N/A';
    final serialNo = unit['serial_no'] ?? 'Unknown';
    final capacityValue = unit['capacity'] ?? '0';
    final capacityUnit = unit['capacity_unit']?['Name'] ?? '';
    final currentStock = unit['current_stock'] ?? 0;

    // Calculate stock percentage (for the progress indicator)
    final capacity = double.tryParse(capacityValue) ?? 1;
    final stockPercentage = (currentStock / capacity).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gas_meter_outlined,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial No: $serialNo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Product: $productName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Capacity: $capacityValue $capacityUnit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Current Stock Level',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stockPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForPercentage(stockPercentage),
                ),
                minHeight: 12,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentStock $capacityUnit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getColorForPercentage(stockPercentage),
                  ),
                ),
                Text(
                  '${(stockPercentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.history),
                    label: Text('View Refill History'),
                    onPressed: () {
                      // Navigate to refill history screen
                      // TODO: Implement navigation to refill history filtered by this unit
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.25) {
      return Colors.red;
    } else if (percentage < 0.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
