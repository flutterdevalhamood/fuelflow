import 'package:flutter/material.dart';
import 'package:sample/src/util/app_colors.dart';

class DriverDetailScreen extends StatefulWidget {
  final Map<String, dynamic> driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen>
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

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    return Scaffold(
      appBar: AppBar(title: Text('Driver Details')),
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
                        return Transform(
                          alignment: Alignment.center,
                          transform:
                              Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // Perspective
                                ..rotateY(_rotationAnimation.value),
                          child: _buildDetailCard(
                            driver['customer']?['Name'] ?? '',
                            driver['Name'] ?? '',
                            driver['Mobile'] ?? '',
                          ),
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

  Widget _buildDetailCard(String customer, String name, String mobile) {
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
                    Icons.account_circle,
                    size: 80,
                    color: Appcolors.textWhiteColor(context),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Driver ID",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.textWhiteColor(context),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow('Customer', customer),
                  SizedBox(height: 20),
                  _buildDetailRow('Driver Name', name),
                  SizedBox(height: 20),
                  _buildDetailRow('Mobile ', mobile),
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
        SizedBox(width: 60),
        Flexible(
          child: Text(
            value ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Appcolors.textWhiteColor(context),
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
