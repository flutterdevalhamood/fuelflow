import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/quantity_input_formatter.dart';

import '../../util/snack.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _capacityUnitController = TextEditingController();
  final TextEditingController _customerSiteController = TextEditingController();

  String? _selectedType;
  String? _selectedCapacityUnit;
  String? _selectedCustomer;
  int? _selectedTypeId;
  int? _selectedCapacityUnitId;
  int? _selectedCustomerId;
  int? _selectedCustomerSiteId;
  late VehicleController _vehicleController;
  bool _isSubmitClicked = false;
  bool _isRegisteringForCustomer = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vehicleController = Provider.of<VehicleController>(
        context,
        listen: false,
      );
      _vehicleController.getVehicleDropDown();
    });
    super.initState();
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _capacityController.dispose();
    _noteController.dispose();
    _typeController.dispose();
    _capacityUnitController.dispose();
    _customerController.dispose();
    _customerSiteController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _plateNumberController.clear();
    _capacityController.clear();
    _noteController.clear();
    _typeController.clear();
    _customerController.clear();
    _capacityUnitController.clear();
    _customerSiteController.clear();
    _selectedTypeId = null;
    _selectedCapacityUnitId = null;
    _selectedCustomerId = null;
    _selectedCustomerSiteId = null;
  }

  Future<void> _registerVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitClicked = true;
      });

      bool isSuccess;

      if (_isRegisteringForCustomer) {
        isSuccess = await _vehicleController.registerVehicleForCustomer(
          _plateNumberController.text.trim(),
          _selectedTypeId,
          _capacityController.text.trim(),
          _noteController.text.trim(),
          _selectedCapacityUnitId ?? 0,
          _selectedCustomerId,
          _selectedCustomerSiteId,
        );
      } else {
        isSuccess = await _vehicleController.registerVehicle(
          _plateNumberController.text.trim(),
          _capacityController.text.trim(),
          _noteController.text.trim(),
          _selectedTypeId,
          _selectedCapacityUnitId ?? 0,
          AuthRepo.customerId,
          1,
        );
      }

      setState(() {
        _isSubmitClicked = false;
      });

      if (isSuccess) {
        showSuccessSnack(
          _isRegisteringForCustomer
              ? "Vehicle registered for customer successfully!"
              : "Vehicle registered successfully!",
        );
        _vehicleController.getVehicleData();

        // Navigate back to vehicle list after success
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.vehicleList,
          removeUntilPageName: Screenroutes.vehicleList,
        );
      } else {
        showErrorSnack("Error registering vehicle");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleController>(
      builder: (context, vehicleController, child) {
        final vehicleTypeData = vehicleController.vehicleTypeData;
        final unitData = vehicleController.unitData;
        final customerData = vehicleController.customerData;
        final customerSiteData = vehicleController.customerSiteData;

        return Scaffold(
          appBar: AppBar(
            title: Text('Vehicle Registration'),
            centerTitle: true,
          ),
          body:
              vehicleTypeData == null ||
                      unitData == null ||
                      customerData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              Text(
                                'Register a New Vehicle',
                                style:
                                    Theme.of(context).textTheme.displayMedium,
                              ),
                              SizedBox(height: 20),

                              // Registration Type Toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                                _isRegisteringForCustomer =
                                                    false;
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
                                                  bottomLeft: Radius.circular(
                                                    8,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                'Register for Myself',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      !_isRegisteringForCustomer
                                                          ? Colors.white
                                                          : Colors
                                                              .blue
                                                              .shade900,
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
                                                _isRegisteringForCustomer =
                                                    true;
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
                                                  bottomRight: Radius.circular(
                                                    8,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                'Register for Customer',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      _isRegisteringForCustomer
                                                          ? Colors.white
                                                          : Colors
                                                              .blue
                                                              .shade900,
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

                              // Customer Dropdown (only shown when registering for customer)
                              if (_isRegisteringForCustomer) ...[
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
                                      (filter, infiniteScrollProps) =>
                                          customerData,
                                  itemAsString: (item) => item['Name'] ?? '',
                                  compareFn:
                                      (item1, item2) =>
                                          item1['id'] == item2['id'],
                                  onChanged: (newValue) async {
                                    if (newValue != null) {
                                      final customerId = newValue['id'] as int?;
                                      final serialNo =
                                          newValue['serial_no'] as String? ??
                                          '';

                                      setState(() {
                                        _selectedCustomerId = customerId;
                                        _customerController.text = serialNo;
                                        _selectedCustomerSiteId = null;
                                        _customerSiteController.clear();
                                      });

                                      // Fetch customer sites when customer is selected
                                      if (customerId != null) {
                                        await _vehicleController
                                            .getCustomerSites(customerId);
                                      }
                                    }
                                  },
                                  selectedItem:
                                      _selectedCustomerId != null
                                          ? customerData.firstWhere(
                                            (refill) =>
                                                refill['id'] ==
                                                _selectedCustomerId,
                                            orElse: () => {},
                                          )
                                          : null,
                                  validator:
                                      _isRegisteringForCustomer
                                          ? (value) {
                                            if (value == null) {
                                              return 'Please select a Customer Name';
                                            }
                                            return null;
                                          }
                                          : null,
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Customer *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.person,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Customer Site Dropdown
                                if (_selectedCustomerId != null)
                                  vehicleController.isLoadingCustomerSites
                                      ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : DropdownSearch<Map<String, dynamic>>(
                                        popupProps: PopupProps.menu(
                                          showSearchBox: true,
                                          fit: FlexFit.tight,
                                          searchFieldProps: TextFieldProps(
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search Customer Site...',
                                            ),
                                          ),
                                        ),
                                        items:
                                            (filter, infiniteScrollProps) =>
                                                customerSiteData ?? [],
                                        itemAsString:
                                            (item) => item['Name'] ?? '',
                                        compareFn:
                                            (item1, item2) =>
                                                item1['id'] == item2['id'],
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            final siteId =
                                                newValue['id'] as int?;
                                            final siteName =
                                                newValue['Name'] as String? ??
                                                '';

                                            setState(() {
                                              _selectedCustomerSiteId = siteId;
                                              _customerSiteController.text =
                                                  siteName;
                                            });
                                          }
                                        },
                                        selectedItem:
                                            _selectedCustomerSiteId != null
                                                ? customerSiteData?.firstWhere(
                                                  (site) =>
                                                      site['id'] ==
                                                      _selectedCustomerSiteId,
                                                  orElse: () => {},
                                                )
                                                : null,
                                        validator:
                                            _isRegisteringForCustomer
                                                ? (value) {
                                                  if (value == null) {
                                                    return 'Please select a Customer Site';
                                                  }
                                                  return null;
                                                }
                                                : null,
                                        decoratorProps: DropDownDecoratorProps(
                                          decoration: InputDecoration(
                                            labelText: 'Customer Site *',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                if (_selectedCustomerId != null)
                                  SizedBox(height: 20),
                              ],

                              DropdownSearch<Map<String, dynamic>>(
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  fit: FlexFit.tight,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search Vehicle Type...',
                                    ),
                                  ),
                                ),
                                items:
                                    (filter, infiniteScrollProps) =>
                                        vehicleTypeData,
                                itemAsString: (item) => item['Name'] ?? '',
                                compareFn:
                                    (item1, item2) =>
                                        item1['id'] == item2['id'],
                                onChanged: (newValue) async {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedTypeId = newValue['id'];
                                      _typeController.text = newValue['Name'];
                                    });
                                  }
                                },
                                selectedItem:
                                    _selectedTypeId != null
                                        ? vehicleTypeData.firstWhere(
                                          (vehicle) =>
                                              vehicle['id'] == _selectedTypeId,
                                          orElse: () => {},
                                        )
                                        : null,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a Type';
                                  }
                                  return null;
                                },
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Type *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.directions_car,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              TextFormField(
                                controller: _plateNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Plate Number *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.confirmation_number,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Plate Number';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _capacityController,
                                      decoration: InputDecoration(
                                        labelText: 'Capacity *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.straighten,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      inputFormatters: [
                                        QuantityInputFormatter(),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter Capacity';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    child: DropdownButtonFormField<int>(
                                      decoration: InputDecoration(
                                        labelText: 'Unit *',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.scale,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      value: _selectedCapacityUnitId,
                                      items:
                                          (unitData ?? []).map((item) {
                                            return DropdownMenuItem<int>(
                                              value: item['id'],
                                              child: Text(item['Name']),
                                              onTap: () {
                                                setState(() {
                                                  _selectedCapacityUnitId =
                                                      item['id'];
                                                });
                                              },
                                            );
                                          }).toList(),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          _selectedCapacityUnitId = newValue;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a Unit';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              TextField(
                                controller: _noteController,
                                decoration: InputDecoration(
                                  labelText: 'Note',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.note,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              SizedBox(height: 100),
                            ],
                          ),
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
                            onPressed:
                                _isSubmitClicked
                                    ? null
                                    : () async {
                                      _registerVehicle();
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
                              backgroundColor: Colors.blue.shade900,
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child:
                                _isSubmitClicked
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      _isRegisteringForCustomer
                                          ? 'Register for Customer'
                                          : 'Register for Myself',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
