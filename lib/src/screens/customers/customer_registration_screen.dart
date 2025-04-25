import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/util/email_formatter.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/mobile_number_formatter.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  _CustomerRegistrationScreenState createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _representativeController =
      TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _secondaryMobileController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int? _IsAdmin = 0;

  @override
  void initState() {
    super.initState();
    _mobileController.text = '+971';
    _secondaryMobileController.text = '+971';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _representativeController.dispose();
    _mobileController.dispose();
    _secondaryMobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerController = Provider.of<CustomerController>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Customer Registration')),
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
                SizedBox(height: 20),
                Text(
                  'Register a New Customer',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.displayMedium, // Use displayMedium
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Is Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Radio(
                      value: 0,
                      groupValue: _IsAdmin,
                      onChanged: (int? value) {
                        if (mounted) {
                          setState(() {
                            _IsAdmin = value;
                          });
                        }
                      },
                    ),
                    Text('No'),
                    Radio(
                      value: 1,
                      groupValue: _IsAdmin,
                      onChanged: (int? value) {
                        if (mounted) {
                          setState(() {
                            _IsAdmin = value;
                          });
                        }
                      },
                    ),
                    Text('Yes'),
                  ],
                ),
                _buildTextField(
                  controller: _nameController,
                  label: 'Company Name*',
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
                  label: 'Representative*',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter representative name';
                    }
                    return null;
                  },
                ),
                _buildMobileTextField(
                  controller: _mobileController,
                  label: 'Mobile*',
                  icon: Icons.phone_android,
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
                _buildMobileTextField(
                  controller: _secondaryMobileController,
                  label: 'Secondary Mobile',
                  icon: Icons.phone_android,
                ),
                _buildTextField(
                  controller: _emailController,

                  label: 'Email*',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [EmailInputFormatter()],
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      bool isSuccess = await customerController
                          .registerCustomer(
                            _nameController.text.trim(),
                            _representativeController.text.trim(),
                            _mobileController.text,
                            _secondaryMobileController.text,
                            _emailController.text,
                            _IsAdmin,
                          );
                      if (isSuccess) {
                        showSuccessSnack("Customer registered successfully!");
                        Navigator.pop(context, true);
                      } else {
                        showErrorSnack("Error registering customer");
                      }

                      // Navigate back
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blue.shade900,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
        validator: validator,
      ),
    );
  }

  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
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
        keyboardType: TextInputType.phone,
        inputFormatters: [
          // FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          LengthLimitingTextInputFormatter(13), // +971 + 9 digits = 13 chars
          MobileNumberFormatter(), // Custom formatter to handle prefix
        ],
        validator: validator,
      ),
    );
  }
}
