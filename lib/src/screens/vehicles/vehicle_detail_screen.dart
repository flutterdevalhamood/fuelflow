import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_sizes.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  void showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: GestureDetector(
              onTap: NavigationService().popNavigation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    print('vehicledetaildata $vehicle');
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Details'),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor, // Use global theme
        iconTheme: Theme.of(context).appBarTheme.iconTheme, // Use global theme
      ),
      body: _getBody(context, vehicle),
    );
  }

  _getBody(BuildContext context, vehicle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),

      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  _buildDetailCard(
                    Icons.person,
                    'Customer',
                    vehicle['customer']?['Name'],
                  ),
                  SizedBox(height: 16),

                  // Vehicle Type
                  _buildDetailCard(
                    Icons.directions_car,
                    'Type',
                    vehicle['type']?['Name'],
                  ),
                  SizedBox(height: 16),

                  // Plate Number
                  _buildDetailCard(
                    Icons.confirmation_number,
                    'Plate Number',
                    vehicle['plate_no'],
                  ),
                  SizedBox(height: 16),

                  // Capacity
                  _buildDetailCard(
                    Icons.storage,
                    'Capacity',
                    '${vehicle['capacity']} ${vehicle['vehicle_capacity_unit']?['Name']}',
                  ),
                  SizedBox(height: 16),

                  // Note
                  _buildDetailCard(Icons.note, 'Note', vehicle['description']),
                  SizedBox(height: 20),
                  if (vehicle['vehicle_images'].isNotEmpty &&
                      vehicle['vehicle_images'] != null)
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 10),
                  if (vehicle['vehicle_images'] != null &&
                      vehicle['vehicle_images'].isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vehicle['vehicle_images'].length,
                        itemBuilder: (context, index) {
                          final image = vehicle['vehicle_images'][index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                showFullScreenImage(context, image['Title']);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  image['Title'],
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 150,
                                      color:
                                          Colors
                                              .grey[300], // Placeholder background
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[600],
                                      ), // Fallback icon
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a detail card
  Widget _buildDetailCard(IconData? icon, String? label, String? value) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label ?? '',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value ?? '',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: AppWidgetSizes.fontSize18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
