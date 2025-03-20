import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_colors.dart';
import '../../util/app_navigation.dart';
import '../../util/app_sizes.dart';

class FuelRefillDataScreen extends StatefulWidget {
  const FuelRefillDataScreen({super.key});

  @override
  State<FuelRefillDataScreen> createState() => _FuelRefillDataScreenState();
}

class _FuelRefillDataScreenState extends State<FuelRefillDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final dropDownKey = GlobalKey<DropdownSearchState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _refillUnitController = TextEditingController();
  late FuelRefillController _fuelRefillController;
  int? _selectedUnitId;
  int? _selectedCustomerId;
  int? _selectedProductId;
  int? _selectedDriverId;
  int? _selectedVehicleId;
  int? _selectedRefillId;
  List<XFile>? _imageFiles;
  bool _isRegistrationComplete = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fuelRefillController = Provider.of<FuelRefillController>(
        context,
        listen: false,
      );
      _fuelRefillController.setUnitController(_unitController);
      _fuelRefillController.setProductController(_productController);
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

  Future<void> _postRefillData() async {
    if (_formKey.currentState!.validate()) {
      bool isSuccess = await _fuelRefillController.postRefillData(
        refillingUnitId: _selectedRefillId,
        qty: _quantityController.text.trim(),
        customerId: _selectedCustomerId,
        unitId: _fuelRefillController.defaultCapacityUnitId,
        productId: _fuelRefillController.defaultProductId,
        driverId: _selectedDriverId ?? 0,
        vehicleId: _selectedVehicleId,
      );
      if (isSuccess) {
        showSuccessSnack("Refill entry Successfull! Add images now...");
        setState(() {
          _isRegistrationComplete = true;
        });
      } else {
        showErrorSnack("Error uploading Refill data");
      }
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = [...?_imageFiles, ...pickedFiles];
      });
    }
  }

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFiles = [...?_imageFiles, pickedFile];
      });
    }
  }

  Future<void> _uploadImages() async {
    final _refillId = _fuelRefillController.refillId;
    if (_imageFiles == null || _imageFiles!.isEmpty) {
      print('No images selected');
      return;
    }

    List<MultipartFile> multipartFiles = [];
    for (var file in _imageFiles!) {
      multipartFiles.add(await MultipartFile.fromFile(file.path));
    }

    if (_refillId != null) {
      bool isSuccess = await _fuelRefillController.uploadRefillImages(
        multipartFiles,
        _refillId.toString(),
      );
      if (isSuccess) {
        showSuccessSnack('Image uploaded successfully');
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.fuelRefillListScreen,
          removeUntilPageName: Screenroutes.fuelRefillListScreen,
        );
      } else {
        showErrorSnack('Error uploading image');
      }
    } else {
      print('Refill ID is null');
    }
  }

  void showFullScreenImage(
    BuildContext context,
    List<XFile> imageFiles,
    int initialIndex,
  ) {
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: NavigationService().popNavigation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          imageFiles[currentIndex] as File,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex =
                                  (currentIndex + 1) % imageFiles.length;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
        final refillData = fuelRefillController.refillUnitsData;
        final defaultProductName = fuelRefillController.defaultProductName;
        final defaultUnitName = fuelRefillController.defaultUnitName;
        final defaultProductId = fuelRefillController.defaultProductId;
        final defaultUnitId = fuelRefillController.defaultCapacityUnitId;
        print('defaultProductName $defaultProductName');
        print('defaultUnitName $defaultUnitName');

        return Scaffold(
          appBar: AppBar(title: Text('Fuel Entry'), centerTitle: true),
          body:
              unitData == null ||
                      productData == null ||
                      customerData == null ||
                      refillData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!_isRegistrationComplete) ...[
                                DropdownSearch<Map<String, dynamic>>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    fit: FlexFit.tight,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Search Serial Number...',
                                      ),
                                    ),
                                  ),
                                  items:
                                      (filter, infiniteScrollProps) =>
                                          refillData,
                                  itemAsString:
                                      (item) => item['serial_no'] ?? '',
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
                                        _selectedRefillId = newValue['id'];
                                        _refillUnitController.text =
                                            newValue['serial_no'];
                                      });
                                      await _fuelRefillController
                                          .getUnitProductDropdown(
                                            _selectedRefillId,
                                          );
                                    }
                                  },
                                  selectedItem:
                                      _selectedRefillId != null
                                          ? refillData.firstWhere(
                                            (refill) =>
                                                refill['id'] ==
                                                _selectedRefillId,
                                          )
                                          : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a Refill ID';
                                    }
                                    return null;
                                  },
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Refill Serial Number',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                DropdownSearch<Map<String, dynamic>>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    fit: FlexFit.tight,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Search customer...',
                                      ),
                                    ),
                                  ),
                                  items:
                                      (filter, infiniteScrollProps) =>
                                          customerData,
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
                                        _customerController.text =
                                            newValue['Name'];
                                      });
                                      await _fuelRefillController
                                          .getDriverVehicleDropdown(
                                            _selectedCustomerId,
                                          );
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
                                      return 'Please select a customer';
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
                                // InkWell(
                                //   onTap: _showCustomerFilterBottomSheet,
                                //   child: IgnorePointer(
                                //     child: TextFormField(
                                //       controller: _customerController,
                                //       decoration: InputDecoration(
                                //         labelText: 'Customer',
                                //         border: OutlineInputBorder(),
                                //         suffixIcon: Icon(Icons.filter_list),
                                //       ),
                                //     ),
                                //   ),
                                // ),
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
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a vehicle';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),

                                TextFormField(
                                  controller: _quantityController,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  readOnly: true,
                                  controller: _unitController,
                                  decoration: InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                ),
                                // DropdownButtonFormField<int>(
                                //   decoration: InputDecoration(
                                //     labelText: 'Unit',
                                //     border: OutlineInputBorder(),
                                //   ),
                                //   value: _selectedUnitId,
                                //   items:
                                //       (unitData ?? []).map((item) {
                                //         return DropdownMenuItem<int>(
                                //           value: item['id'],
                                //           child: Text(item['Name']),
                                //           onTap: () {
                                //             setState(() {
                                //               _selectedUnitId = item['id'];
                                //             });
                                //           },
                                //         );
                                //       }).toList(),
                                //   onChanged: (int? newValue) {
                                //     setState(() {
                                //       _selectedUnitId = newValue;
                                //       // _customerController.text = newValue ?? '';
                                //     });
                                //   },
                                //   validator: (value) {
                                //     if (value == null) {
                                //       return 'Please select a unit';
                                //     }
                                //     return null;
                                //   },
                                // ),
                                SizedBox(height: 20),
                                TextFormField(
                                  readOnly: true,
                                  controller: _productController,
                                  decoration: InputDecoration(
                                    labelText: 'Product',
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                ),
                                // DropdownButtonFormField<int>(
                                //   decoration: InputDecoration(
                                //     labelText: 'Product',
                                //     border: OutlineInputBorder(),
                                //   ),
                                //   value: _selectedProductId,
                                //   items:
                                //       (productData ?? []).map((item) {
                                //         return DropdownMenuItem<int>(
                                //           value: item['id'],
                                //           child: Text(item['Name']),
                                //           onTap: () {
                                //             setState(() {
                                //               _selectedProductId = item['id'];
                                //             });
                                //           },
                                //         );
                                //       }).toList(),
                                //   onChanged: (int? newValue) {
                                //     setState(() {
                                //       _selectedProductId = newValue;
                                //       // _customerController.text = newValue ?? '';
                                //     });
                                //   },
                                //   validator: (value) {
                                //     if (value == null) {
                                //       return 'Please select a product';
                                //     }
                                //     return null;
                                //   },
                                // ),
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
                                SizedBox(height: 100),
                              ],
                              if (_isRegistrationComplete) ...[
                                Text(
                                  'Pictures',
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),

                                _imageFiles != null && _imageFiles!.isNotEmpty
                                    ? GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                      itemCount: _imageFiles!.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showFullScreenImage(
                                                  context,
                                                  _imageFiles!,
                                                  index,
                                                );
                                              },
                                              child: Image.file(
                                                File(_imageFiles![index].path),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _imageFiles!.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                margin: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                    : Text('No images selected.'),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _pickImages();
                                      },
                                      icon: Icon(
                                        Icons.photo_library,
                                        color: Appcolors.textWhiteColor(
                                          context,
                                        ),
                                      ),
                                      label: Text(
                                        'Gallery',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium!.copyWith(
                                          color: Appcolors.textWhiteColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _takePicture();
                                      },
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: Appcolors.textWhiteColor(
                                          context,
                                        ),
                                      ),
                                      label: Center(
                                        child: Text(
                                          'Camera',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.copyWith(
                                            color: Appcolors.textWhiteColor(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 80),
                              ],
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
                            onPressed: () async {
                              !_isRegistrationComplete
                                  ? _postRefillData()
                                  : _uploadImages();
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
                              !_isRegistrationComplete
                                  ? 'Save'
                                  : 'Upload images',
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
