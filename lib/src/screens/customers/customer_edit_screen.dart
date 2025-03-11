import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';

import '../../util/snack.dart';

class CustomerEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const CustomerEditScreen({super.key, required this.data});

  @override
  _CustomerEditScreenState createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _representativeController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late CustomerController _customerController;

  File? selectedFile;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _customerController = Provider.of<CustomerController>(
        context,
        listen: false,
      );
      _customerController.getCustomerData();
    });
    super.initState();

    _companyNameController = TextEditingController(text: widget.data['Name']);
    _representativeController = TextEditingController(
      text: widget.data['representative'],
    );
    _mobileController = TextEditingController(text: widget.data['mobile']);
    _emailController = TextEditingController(text: widget.data['email']);
  }

  @override
  void dispose() {
    // Dispose controllers
    _companyNameController.dispose();
    _representativeController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final id = widget.data['id'];
    final companyName = _companyNameController.text.trim();
    final representative = _representativeController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();

    if (id != null) {
      bool isSuccess = await _customerController.updateCustomer(
        id,
        companyName,
        representative,
        mobile,
        email,
      );
      if (isSuccess) {
        showSuccessSnack('Vehicle updated successfully');
        Navigator.pop(context, true);
      } else {
        showErrorSnack('Error updating data');
      }
    } else {
      showErrorSnack("cannot find Customer id");
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerController = Provider.of<CustomerController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Customer'),
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
                  label: 'Company Name',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _representativeController,
                  label: 'Representative',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter representative name';
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
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email address';
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
