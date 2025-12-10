import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum TripStatus {
  notStarted,
  running,
  atCustomer,
  filling,
  returning,
  completed,
}

class FuelTripScreen extends StatefulWidget {
  const FuelTripScreen({super.key});

  @override
  State<FuelTripScreen> createState() => _FuelTripScreenState();
}

class _FuelTripScreenState extends State<FuelTripScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _startMeterController = TextEditingController();
  final TextEditingController _endMeterController = TextEditingController();

  // State variables
  TripStatus _tripStatus = TripStatus.notStarted;
  File? _startMeterImage;
  File? _startFillingImage;
  File? _endFillingImage;
  File? _endMeterImage;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _truckAnimation;

  // Trip data
  String driverName = "John Doe";
  String vehicleNumber = "ABC-1234";
  String customerName = "XYZ Fuel Station";

  Set<String> _selectedProblems = {};
  final List<String> _problemOptions = ['Traffic', 'Maintenance', 'Others'];
  final TextEditingController _otherProblemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _truckAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _startMeterController.dispose();
    _endMeterController.dispose();
    _otherProblemController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage(Function(File) onImagePicked) async {
  //   final XFile? image = await _picker.pickImage(source: ImageSource.camera);
  //   if (image != null) {
  //     setState(() {
  //       onImagePicked(File(image.path));
  //     });
  //   }
  // }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          onImagePicked(File(image.path));
        });
      }
    } catch (e) {
      // Fallback if camera/gallery not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker not available in simulator'),
        ),
      );
    }
  }

  String _getStatusText() {
    switch (_tripStatus) {
      case TripStatus.notStarted:
        return "Not Started";
      case TripStatus.running:
        return "Running";
      case TripStatus.atCustomer:
        return "Idle - At Customer";
      case TripStatus.filling:
        return "Filling Fuel";
      case TripStatus.returning:
        return "Returning to Depot";
      case TripStatus.completed:
        return "Completed";
    }
  }

  Widget _buildProblemsSection() {
    return _buildSectionCard(
      title: 'Report Problems (Optional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select any problems encountered:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _problemOptions.map((problem) {
                  final isSelected = _selectedProblems.contains(problem);
                  return FilterChip(
                    label: Text(problem),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedProblems.add(problem);
                        } else {
                          _selectedProblems.remove(problem);
                          if (problem == 'Others') {
                            _otherProblemController.clear();
                          }
                        }
                      });
                    },
                    selectedColor: Colors.orange.shade200,
                    checkmarkColor: Colors.orange.shade900,
                    backgroundColor: Colors.grey.shade200,
                  );
                }).toList(),
          ),
          if (_selectedProblems.contains('Others')) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _otherProblemController,
              decoration: const InputDecoration(
                labelText: 'Describe other problems',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
                hintText: 'Enter details...',
              ),
              maxLines: 2,
            ),
          ],
          if (_selectedProblems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Problems reported: ${_selectedProblems.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_tripStatus) {
      case TripStatus.notStarted:
        return Colors.grey;
      case TripStatus.running:
        return Colors.green;
      case TripStatus.atCustomer:
        return Colors.orange;
      case TripStatus.filling:
        return Colors.blue;
      case TripStatus.returning:
        return Colors.purple;
      case TripStatus.completed:
        return Colors.teal;
    }
  }

  Widget _buildTruckAnimation() {
    if (_tripStatus != TripStatus.running &&
        _tripStatus != TripStatus.returning) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _truckAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_truckAnimation.value, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Icon(
              Icons.local_shipping,
              size: 60,
              color: Colors.blue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(File? image, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (image != null)
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(image, fit: BoxFit.cover),
            ),
          )
        else
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.image, size: 40, color: Colors.grey),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Delivery Trip')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with trip info and status
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver: $driverName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vehicle: $vehicleNumber',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer: $customerName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTruckAnimation(),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Start Flow Meter Section
                    if (_tripStatus == TripStatus.notStarted) ...[
                      _buildSectionCard(
                        title: '1. Start Flow Meter Reading',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _startMeterController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Flow Meter Reading',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.speed),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter flow meter reading';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildImagePreview(
                                  _startMeterImage,
                                  'Flow Meter Photo',
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _pickImage(
                                        (file) => _startMeterImage = file,
                                      ),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Take Photo'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate() &&
                                    _startMeterImage != null) {
                                  setState(() {
                                    _tripStatus = TripStatus.running;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter reading and take photo',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text(
                                'Start Journey',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Running Journey
                    if (_tripStatus == TripStatus.running) ...[
                      _buildSectionCard(
                        title: '2. Journey to Customer',
                        child: Column(
                          children: [
                            const Icon(
                              Icons.directions_car,
                              size: 60,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Journey in Progress...',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _tripStatus = TripStatus.atCustomer;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text(
                                'Arrived at Customer',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // At Customer - Fuel Filling
                    if (_tripStatus == TripStatus.atCustomer) ...[
                      _buildSectionCard(
                        title: '3. Fuel Filling Process',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildImagePreview(
                                  _startFillingImage,
                                  'Start Filling Photo',
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _pickImage(
                                        (file) => _startFillingImage = file,
                                      ),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Start Filling'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (_startFillingImage != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildImagePreview(
                                    _endFillingImage,
                                    'End Filling Photo',
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _pickImage(
                                          (file) => _endFillingImage = file,
                                        ),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('End Filling'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_endFillingImage != null) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _endMeterController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'End Flow Meter Reading',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.speed),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildImagePreview(
                                    _endMeterImage,
                                    'End Meter Photo',
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _pickImage(
                                          (file) => _endMeterImage = file,
                                        ),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_endMeterController.text.isNotEmpty &&
                                      _endMeterImage != null) {
                                    setState(() {
                                      _tripStatus = TripStatus.returning;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please complete all fields',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Text(
                                  'Start Return Journey',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    _buildProblemsSection(),

                    // Return Journey
                    if (_tripStatus == TripStatus.returning) ...[
                      _buildSectionCard(
                        title: '4. Return Journey',
                        child: Column(
                          children: [
                            const Icon(
                              Icons.home,
                              size: 60,
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Returning to Depot...',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _tripStatus = TripStatus.completed;
                                });
                                _showTripSummary();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                              child: const Text(
                                'Arrived at Depot',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Completed
                    if (_tripStatus == TripStatus.completed) ...[
                      _buildSectionCard(
                        title: 'Trip Completed',
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Trip Completed Successfully!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _showTripSummary();
                              },
                              child: const Text('View Trip Summary'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  void _showTripSummary() {
    final startReading = double.tryParse(_startMeterController.text) ?? 0;
    final endReading = double.tryParse(_endMeterController.text) ?? 0;
    final fuelDelivered = endReading - startReading;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Trip Summary'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Driver', driverName),
                  _buildSummaryRow('Vehicle', vehicleNumber),
                  _buildSummaryRow('Customer', customerName),
                  const Divider(),
                  _buildSummaryRow(
                    'Start Meter Reading',
                    '${startReading.toStringAsFixed(2)} L',
                  ),
                  _buildSummaryRow(
                    'End Meter Reading',
                    '${endReading.toStringAsFixed(2)} L',
                  ),
                  _buildSummaryRow(
                    'Fuel Delivered',
                    '${fuelDelivered.toStringAsFixed(2)} L',
                    isHighlight: true,
                  ),
                  const Divider(),
                  _buildSummaryRow('Photos Captured', '4'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Reset for new trip
                  setState(() {
                    _tripStatus = TripStatus.notStarted;
                    _startMeterController.clear();
                    _endMeterController.clear();
                    _startMeterImage = null;
                    _startFillingImage = null;
                    _endFillingImage = null;
                    _endMeterImage = null;
                  });
                },
                child: const Text('Start New Trip'),
              ),
            ],
          ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
