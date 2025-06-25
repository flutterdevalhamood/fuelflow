import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/mobile_number_formatter.dart';
import 'package:sample/src/util/snack.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  _DriverRegistrationScreenState createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  late VehicleController _productController;
  int? _selectedCustomerId;
  bool _isSubmitClicked = false;
  bool _isRegisteringForCustomer =
      false; // Toggle between self and customer registration

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productController = Provider.of<VehicleController>(
        context,
        listen: false,
      );
      _productController.getVehicleDropDown();
    });

    super.initState();
    _mobileController.text = '+971';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _driverController.clear();
    _mobileController.text = '+971';
    _selectedCustomerId = null;
  }

  @override
  Widget build(BuildContext context) {
    final driverController = Provider.of<DriverController>(context);
    return Consumer<VehicleController>(
      builder: (context, vehicleController, child) {
        final customerData = vehicleController.customerData;
        return Scaffold(
          appBar: AppBar(title: Text('Driver Registration')),
          body:
              customerData == null
                  ? Center(child: CircularProgressIndicator())
                  : Container(
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
                              'Register a New Driver',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            SizedBox(height: 20),

                            // Registration Type Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Registration Type',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isRegisteringForCustomer = false;
                                              _resetForm();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  !_isRegisteringForCustomer
                                                      ? Colors.blue.shade900
                                                      : Colors.transparent,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                bottomLeft: Radius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Register for Myself',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    !_isRegisteringForCustomer
                                                        ? Colors.white
                                                        : Colors.blue.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isRegisteringForCustomer = true;
                                              _resetForm();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _isRegisteringForCustomer
                                                      ? Colors.blue.shade900
                                                      : Colors.transparent,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                bottomRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Register for Customer',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    _isRegisteringForCustomer
                                                        ? Colors.white
                                                        : Colors.blue.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),

                            // Customer Dropdown (only show when registering for customer)
                            if (_isRegisteringForCustomer) ...[
                              DropdownButtonFormField<int>(
                                value: _selectedCustomerId,
                                decoration: InputDecoration(
                                  labelText: 'Select Customer*',
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.blue.shade900,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                items:
                                    customerData.map<DropdownMenuItem<int>>((
                                      customer,
                                    ) {
                                      return DropdownMenuItem<int>(
                                        value: customer['id'],
                                        child: Text(
                                          customer['Name'] ??
                                              'Unknown Customer',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedCustomerId = newValue;
                                    // Optionally pre-fill customer name
                                    if (newValue != null) {
                                      final selectedCustomer = customerData
                                          .firstWhere(
                                            (customer) =>
                                                customer['id'] == newValue,
                                            orElse: () => {},
                                          );
                                      if (selectedCustomer.isNotEmpty) {
                                        _nameController.text =
                                            selectedCustomer['Name'] ?? '';
                                      }
                                    }
                                  });
                                },
                                validator:
                                    _isRegisteringForCustomer
                                        ? (value) {
                                          if (value == null) {
                                            return 'Please select a customer';
                                          }
                                          return null;
                                        }
                                        : null,
                              ),
                              SizedBox(height: 20),
                            ],

                            // Driver Name Field
                            _buildTextField(
                              controller: _driverController,
                              label: 'Driver Name*',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the driver name';
                                }
                                return null;
                              },
                            ),

                            // Mobile Number Field
                            _buildMobileTextField(
                              controller: _mobileController,
                              label: 'Mobile Number*',
                              icon: Icons.phone_android,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                if (!value.startsWith('+971')) {
                                  return 'Mobile number must start with +971';
                                }
                                if (!RegExp(
                                  r'^\+971[0-9]{9}$',
                                ).hasMatch(value)) {
                                  return 'Enter a valid UAE mobile number (e.g., +971501234567)';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 30),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitClicked
                                        ? null
                                        : () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _isSubmitClicked = true;
                                            });

                                            bool isSuccess;

                                            if (_isRegisteringForCustomer) {
                                              // Register driver for customer
                                              isSuccess = await driverController
                                                  .registerDriverForCustomer(
                                                    _driverController.text
                                                        .trim(),
                                                    _mobileController.text,
                                                    _selectedCustomerId,
                                                  );
                                            } else {
                                              // Register driver for self (existing functionality)
                                              isSuccess = await driverController
                                                  .registerDriver(
                                                    _driverController.text
                                                        .trim(),
                                                    _mobileController.text,
                                                    AuthRepo
                                                        .customerId, // No customer ID for self registration
                                                  );
                                            }

                                            setState(() {
                                              _isSubmitClicked = false;
                                            });

                                            if (isSuccess) {
                                              showSuccessSnack(
                                                _isRegisteringForCustomer
                                                    ? "Driver registered for customer successfully!"
                                                    : "Driver registered successfully!",
                                              );
                                              Navigator.pop(context, true);
                                            } else {
                                              showErrorSnack(
                                                "Error registering driver. Please try again.",
                                              );
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.blue.shade900,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                ),
                                child:
                                    _isSubmitClicked
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Submitting...',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          _isRegisteringForCustomer
                                              ? 'Register for Customer'
                                              : 'Register for Myself',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
        );
      },
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
        validator: validator,
        inputFormatters: [
          LengthLimitingTextInputFormatter(13),
          MobileNumberFormatter(),
        ],
      ),
    );
  }
}
