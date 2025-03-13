import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/driver_controller.dart';

import '../../util/snack.dart';

class DriverEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const DriverEditScreen({super.key, required this.data});

  @override
  _DriverEditScreenState createState() => _DriverEditScreenState();
}

class _DriverEditScreenState extends State<DriverEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _mobileController;
  late DriverController _driverController;
  File? selectedFile;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _driverController = Provider.of<DriverController>(context, listen: false);
      _driverController.getDriverData();
    });
    super.initState();

    _companyNameController = TextEditingController(text: widget.data['Name']);
    _mobileController = TextEditingController(text: widget.data['mobile']);
  }

  @override
  void dispose() {
    // Dispose controllers
    _companyNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final id = widget.data['id'];
    final companyName = _companyNameController.text.trim();
    final mobile = _mobileController.text.trim();

    if (id != null) {
      bool isSuccess = await _driverController.updateDriver(
        id,
        companyName,
        mobile,
      );
      if (isSuccess) {
        showSuccessSnack('Driver updated successfully');
        Navigator.pop(context, true);
      } else {
        showErrorSnack('Error updating data');
      }
    } else {
      showErrorSnack("cannot find Driver id");
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverController = Provider.of<DriverController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Driver'),
        actions: [
          IconButton(
            onPressed: () {
              saveEditedData();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Driver Name',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _mobileController,
                  label: 'Mobile',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (!value.startsWith('+971')) {
                      return 'Mobile number must start with +971';
                    }
                    if (!RegExp(r'^\+971[0-9]{9}$').hasMatch(value)) {
                      return 'Enter a valid UAE mobile number (e.g., +971501234567)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
