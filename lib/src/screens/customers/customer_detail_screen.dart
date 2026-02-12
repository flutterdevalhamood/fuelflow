import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../../providers/customer_controller.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late VehicleController _vehicleController;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vehicleController = Provider.of<VehicleController>(
        context,
        listen: false,
      );
      _vehicleController.getVehicleData();
    });
  }

  void _vehicleDetails(String plateNo) async {
    final vehicle = _vehicleController.vehicleData?.firstWhere(
      (vehicle) => vehicle['plate_no'] == plateNo,
      orElse: () => {},
    );
    if (vehicle != null) {
      final result = await NavigationService().pushNavigation(
        Screenroutes.vehicleDetail,
        arguments: vehicle,
      );

      if (result == true) {
        _vehicleController.getVehicleData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle with plate number $plateNo not found')),
      );
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
    final watch = context.watch<VehicleController>();
    final vehicles =
        watch.vehicleData != null
            ? (watch.vehicleData ?? [])
                .where(
                  (vehicle) =>
                      vehicle['plate_no'].toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (vehicle['type']?['Name']?.toLowerCase() ?? '').contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList()
            : [];
    final customer = widget.customer;
    final myVehicleData = widget.customer['my_vehicles'];
    final myDriverData = widget.customer['my_drivers'];
    return Scaffold(
      appBar: AppBar(title: Text('Customer Details')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(
                Icons.business,
                'Company Name',
                customer['Name'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(
                Icons.person,
                'Representative',
                customer['representative'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(
                Icons.phone_android,
                'Mobile',
                customer['mobile'] ?? '',
              ),
              SizedBox(height: 16),
              _buildDetailCard(Icons.email, 'Email', customer['email'] ?? ''),
              SizedBox(height: 24),
              // if (myVehicleData != null && myVehicleData.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _navigateToMyVehicles(widget.customer);
                    },
                    child: Text(
                      'Vehicles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      // Replace with the actual color variable or use Colors.red
                      borderRadius: BorderRadius.circular(23.0),
                    ),
                    child: Center(
                      child: Text(
                        '${myVehicleData.length}',
                        style: TextStyle(
                          color: Colors.white,
                        ), // Replace 'colorwhite' with Colors.white
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _navigateToMyDrivers(widget.customer);
                    },
                    child: Text(
                      'Drivers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(23.0),
                    ),
                    child: Center(
                      child: Text(
                        '${myDriverData.length}',
                        style: TextStyle(
                          color: Colors.white,
                        ), // Replace 'colorwhite' with Colors.white
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

Widget _buildDetailCard(IconData icon, String label, String value) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.blue.shade900),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
