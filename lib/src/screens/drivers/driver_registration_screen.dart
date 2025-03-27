import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/driver_controller.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
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
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .displayMedium, // Use displayMedium
                            ),
                            SizedBox(height: 20),
                            DropdownSearch<Map<String, dynamic>>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                fit: FlexFit.tight,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search Customer Name...',
                                  ),
                                ),
                              ),
                              items:
                                  (filter, infiniteScrollProps) => customerData,
                              itemAsString: (item) => item['Name'] ?? '',
                              compareFn: (
                                Map<String, dynamic> item1,
                                Map<String, dynamic> item2,
                              ) {
                                return item1['id'] ==
                                    item2['id']; // Compare items by their ID
                              },
                              onChanged: (
                                Map<String, dynamic>? newValue,
                              ) async {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCustomerId = newValue['id'];
                                    _nameController.text = newValue['Name'];
                                  });
                                }
                              },
                              selectedItem:
                                  _selectedCustomerId != null
                                      ? customerData.firstWhere(
                                        (customer) =>
                                            customer['id'] ==
                                            _selectedCustomerId,
                                      )
                                      : null,
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a Customer Name';
                                }
                                return null;
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Customer',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildTextField(
                              controller: _driverController,
                              label: 'Driver Name',
                              icon: Icons.business,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the driver name';
                                }
                                return null;
                              },
                            ),
                            _buildMobileTextField(
                              controller: _mobileController,
                              label: 'Mobile',
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
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  bool isSuccess = await driverController
                                      .registerDriver(
                                        _driverController.text.trim(),
                                        _mobileController.text,
                                        _selectedCustomerId,
                                      );
                                  if (isSuccess) {
                                    showSuccessSnack(
                                      "Driver registered successfully!",
                                    );
                                    Navigator.pop(context, true);
                                  } else {
                                    showErrorSnack("Error registering driver");
                                  }

                                  // Navigate back
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
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
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
    required String? Function(String?) validator,
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
