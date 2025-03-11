import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_sizes.dart';

class FuelRefillingScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const FuelRefillingScreen({Key? key, required this.vehicle})
    : super(key: key);

  @override
  _FuelRefillingScreenState createState() => _FuelRefillingScreenState();
}

class _FuelRefillingScreenState extends State<FuelRefillingScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _vehiclePhoto;
  File? _flowMeterStartPhoto;
  File? _flowMeterEndPhoto;
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _startMeterController = TextEditingController();
  TextEditingController _endMeterController = TextEditingController();
  String _selectedUnit = 'liters'; // Default unit
  bool _isRefueling = false;

  Future<void> _takePhoto(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        if (type == 'vehicle') {
          _vehiclePhoto = File(image.path);
        } else if (type == 'flowStart') {
          _flowMeterStartPhoto = File(image.path);
        } else if (type == 'flowEnd') {
          _flowMeterEndPhoto = File(image.path);
        }
      });
    }
  }

  void _startRefueling() {
    if (_vehiclePhoto == null ||
        _flowMeterStartPhoto == null ||
        _startMeterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please capture photos and enter the start meter reading.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isRefueling = true;
    });
  }

  void _finishRefueling() {
    if (_quantityController.text.isEmpty || _endMeterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the quantity dispensed and end meter reading.',
          ),
        ),
      );
      return;
    }
    if (_flowMeterEndPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please take the flow meter end photo.')),
      );
      return;
    }
    // Save the data or perform further actions
    print('Refueling completed for ${widget.vehicle['plateNumber']}');
    print('Quantity: ${_quantityController.text} $_selectedUnit');
    print('Start Meter: ${_startMeterController.text}');
    print('End Meter: ${_endMeterController.text}');
    Navigator.pop(context);
  }

  Widget _buildVehicleCard(IconData? icon, String? label, String? value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vehicle Refueling')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleCard(
                Icons.confirmation_number,
                'Vehicle Number',
                widget.vehicle['plateNumber'],
              ),
              // Vehicle Number
              SizedBox(height: 5),

              SizedBox(height: 20),

              // Vehicle Photo Section
              _buildPhotoSection(
                title: 'Vehicle Photo',
                photo: _vehiclePhoto,
                onTap: () => _takePhoto('vehicle'),
              ),
              SizedBox(height: 20),

              // Flow Meter Photo (Start) Section
              _buildPhotoSection(
                title: 'Flow Meter Photo (Start)',
                photo: _flowMeterStartPhoto,
                onTap: () => _takePhoto('flowStart'),
              ),
              SizedBox(height: 10),

              // Start Meter Reading
              Text(
                'Start Meter Reading',
                style: TextStyle(
                  fontSize: 14,
                  color: Appcolors.textLightGrayColor(context),
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: _startMeterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintText: 'Enter start meter reading',
                ),
              ),
              SizedBox(height: 20),

              // Quantity Dispensed with Dropdown
              Text(
                'Quantity Dispensed',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'Enter quantity',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      items:
                          ['liters', 'gallons'].map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Flow Meter Photo (End) Section (Visible only during refueling)
              if (_isRefueling)
                _buildPhotoSection(
                  title: 'Flow Meter Photo (End)',
                  photo: _flowMeterEndPhoto,
                  onTap: () => _takePhoto('flowEnd'),
                ),
              if (_isRefueling) SizedBox(height: 10),

              // End Meter Reading (Visible only during refueling)
              if (_isRefueling)
                Text(
                  'End Meter Reading',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              if (_isRefueling) SizedBox(height: 5),
              if (_isRefueling)
                TextField(
                  controller: _endMeterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    hintText: 'Enter end meter reading',
                  ),
                ),
              if (_isRefueling) SizedBox(height: 20),

              // Start/Finish Buttons
              if (!_isRefueling)
                ElevatedButton(
                  onPressed: _startRefueling,
                  child: Text(
                    'Start Refueling',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (_isRefueling)
                ElevatedButton(
                  onPressed: _finishRefueling,
                  child: Text(
                    'Finish Refueling',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required File? photo,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child:
                photo == null
                    ? Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
          ),
        ),
      ],
    );
  }
}
