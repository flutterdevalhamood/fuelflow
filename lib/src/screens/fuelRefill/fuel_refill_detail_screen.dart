import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';

class FuelRefillDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const FuelRefillDetailScreen({super.key, required this.data});

  @override
  State<FuelRefillDetailScreen> createState() => _FuelRefillDetailScreenState();
}

class _FuelRefillDetailScreenState extends State<FuelRefillDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    // Define slide animation
    _rotationAnimation = Tween<double>(
      begin: 0, // Start with no rotation
      end: 2 * 3.14159, // Rotate 360 degrees (2 * pi radians)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation when the screen loads
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final refillData = widget.data;
    return Scaffold(
      appBar: AppBar(title: Text('Fuel Refill Details')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Swipe left or right to trigger animation
                      if (details.primaryDelta! < 0) {
                        _controller.forward(); // Slide out to the left
                      } else if (details.primaryDelta! > 0) {
                        _controller.reverse(); // Slide in from the left
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Transform(
                              alignment: Alignment.center,
                              transform:
                                  Matrix4.identity()
                                    ..setEntry(3, 2, 0.001) // Perspective
                                    ..rotateY(_rotationAnimation.value),
                              child: _buildDetailCard(
                                (refillData['qty'].toString()) ?? '',
                                refillData['customer']?['name'] ?? '',
                                refillData['vehicle']?['plate_no'] ?? '',
                                refillData['product']?['Name'] ?? '',
                                refillData['driver']?['Name'] ?? '',
                              ),
                            ),
                            SizedBox(height: 20),
                            if (refillData['refil_images'] != null &&
                                refillData['refil_images'].isNotEmpty)
                              Text(
                                'Images',
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            SizedBox(height: 10),
                            if (refillData['refil_images'] != null &&
                                refillData['refil_images'].isNotEmpty)
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: refillData['refil_images'].length,
                                  itemBuilder: (context, index) {
                                    final image =
                                        refillData['refil_images'][index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          showFullScreenImage(
                                            context,
                                            image['Title'],
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            image['Title'],
                                            width: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
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
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String qty,
    String customer,
    String vehicle,
    String product,
    String driver,
  ) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 350,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade200, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_gas_station,
                    size: 80,
                    color: Appcolors.textWhiteColor(context),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Refill Data",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.textWhiteColor(context),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow('Quantity', qty),
                  SizedBox(height: 20),
                  _buildDetailRow('Customer', customer),
                  SizedBox(height: 20),
                  _buildDetailRow('Driver', vehicle),
                  SizedBox(height: 20),
                  _buildDetailRow('Product', product),
                  SizedBox(height: 20),
                  _buildDetailRow('Driver ', driver),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String? label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.textWhiteColor(context),
          ),
        ),
        Text(
          value ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolors.textWhiteColor(context),
          ),
        ),
      ],
    );
  }
}
