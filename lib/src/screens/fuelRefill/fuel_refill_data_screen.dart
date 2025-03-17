import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';

import '../../util/app_colors.dart';
import '../../util/app_sizes.dart';

class FuelRefillDataScreen extends StatefulWidget {
  const FuelRefillDataScreen({super.key});

  @override
  State<FuelRefillDataScreen> createState() => _FuelRefillDataScreenState();
}

class _FuelRefillDataScreenState extends State<FuelRefillDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  late FuelRefillController _fuelRefillController;

  String? _selectedUnit;
  String? _selectedCustomer;
  String? _selectedProduct;
  String? _selectedDriver;
  String? _selectedVehicle;
  int? _selectedUnitId;
  int? _selectedCustomerId;
  int? _selectedProductId;
  int? _selectedDriverId;
  int? _selectedVehicleId;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fuelRefillController = Provider.of<FuelRefillController>(
        context,
        listen: false,
      );
      _fuelRefillController.getFuelRefillDropdown();
    });
    super.initState();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerController.dispose();
    _unitController.dispose();
    _productController.dispose();
    _driverController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  // void _showCustomerFilterBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) {
  //       return Consumer<FuelRefillController>(
  //         builder: (context, fuelRefillController, child) {
  //           final customerData = fuelRefillController.customerData;
  //           return Container(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   'Select Customer',
  //                   style: Theme.of(context).textTheme.bodyLarge,
  //                 ),
  //                 SizedBox(height: 20),
  //                 if (customerData != null)
  //                   Container(
  //                     height: 60,
  //                     width: double.infinity,
  //                     child: ListView.builder(
  //                       shrinkWrap: true,
  //                       physics: NeverScrollableScrollPhysics(),
  //                       scrollDirection: Axis.horizontal,
  //                       itemCount: customerData.length,
  //                       itemBuilder: (context, index) {
  //                         final customer = customerData[index];
  //                         return GestureDetector(
  //                           onTap: () async {
  //                             setState(() {
  //                               _selectedCustomerId = customer['id'];
  //                               _customerController.text = customer['Name'];
  //                             });
  //                             await _fuelRefillController
  //                                 .getDriverVehicleDropdown(
  //                                   _selectedCustomerId,
  //                                 );
  //                             Navigator.pop(context); // Close the bottom sheet
  //                           },
  //                           child: Container(
  //                             margin: EdgeInsets.only(
  //                               right: 10,
  //                             ), // Spacing between items
  //                             padding: EdgeInsets.symmetric(
  //                               horizontal: 16,
  //                               vertical: 8,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color:
  //                                   _selectedCustomerId == customer['id']
  //                                       ? Colors.blue.withOpacity(0.2)
  //                                       : Colors.grey.withOpacity(0.1),
  //                               borderRadius: BorderRadius.circular(10),
  //                               border: Border.all(
  //                                 color:
  //                                     _selectedCustomerId == customer['id']
  //                                         ? Colors.blue
  //                                         : Colors.transparent,
  //                                 width: 2,
  //                               ),
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 customer['Name'],
  //                                 style: TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight:
  //                                       _selectedCustomerId == customer['id']
  //                                           ? FontWeight.bold
  //                                           : FontWeight.normal,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 SizedBox(height: 20),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showCustomerFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<FuelRefillController>(
          builder: (context, fuelRefillController, child) {
            final customerData = fuelRefillController.customerData;
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Customer',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  if (customerData != null)
                    SizedBox(
                      height: 30, // Fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: customerData.length,
                        itemBuilder: (context, index) {
                          final customer = customerData[index];
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                _selectedCustomerId = customer['id'];
                                _customerController.text = customer['Name'];
                              });
                              await _fuelRefillController
                                  .getDriverVehicleDropdown(
                                    _selectedCustomerId,
                                  );
                              Navigator.pop(context); // Close the bottom sheet
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: 10,
                              ), // Spacing between items
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _selectedCustomerId == customer['id']
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      _selectedCustomerId == customer['id']
                                          ? Colors.blue
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: IntrinsicWidth(
                                child: Center(
                                  child: Text(
                                    customer['Name'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          _selectedCustomerId == customer['id']
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FuelRefillController>(
      builder: (context, fuelRefillController, child) {
        final unitData = fuelRefillController.unitData;
        final productData = fuelRefillController.productData;
        final customerData = fuelRefillController.customerData;
        final driverData = fuelRefillController.driverData;
        final vehicleData = fuelRefillController.vehicleData;
        print('CustomerDataaasss $customerData');
        print('unitDatasss $unitData');
        print('productDatasss $productData');
        return Scaffold(
          appBar: AppBar(title: Text('Fuel Entry'), centerTitle: true),
          body:
              unitData == null || productData == null || customerData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedUnitId,
                              items:
                                  (unitData ?? []).map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item['id'],
                                      child: Text(item['Name']),
                                      onTap: () {
                                        setState(() {
                                          _selectedUnitId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedUnitId = newValue;
                                  // _customerController.text = newValue ?? '';
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Product',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedProductId,
                              items:
                                  (productData ?? []).map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item['id'],
                                      child: Text(item['Name']),
                                      onTap: () {
                                        setState(() {
                                          _selectedProductId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedProductId = newValue;
                                  // _customerController.text = newValue ?? '';
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            InkWell(
                              onTap: _showCustomerFilterBottomSheet,
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: _customerController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.filter_list),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Driver',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedDriverId,
                              items:
                                  (driverData ?? []).map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item['id'],
                                      child: Text(item['Name'] ?? ''),
                                      onTap: () {
                                        setState(() {
                                          _selectedDriverId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedDriverId = newValue;
                                });
                              },
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Vehicle',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedVehicleId,
                              items:
                                  (vehicleData ?? []).map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item['id'],
                                      child: Text(item['plate_no'] ?? ''),
                                      onTap: () {
                                        setState(() {
                                          _selectedVehicleId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedVehicleId = newValue;
                                });
                              },
                            ),
                            SizedBox(height: 100),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              // !_isRegistrationComplete
                              //     ? _registerVehicle()
                              //     : _uploadImages();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'Save',
                              // !_isRegistrationComplete
                              //     ? 'Save'
                              //     : 'Upload images',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(
                                color: Appcolors.textWhiteColor(context),
                                fontSize: AppWidgetSizes.fontSize18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}
