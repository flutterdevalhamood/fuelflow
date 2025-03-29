import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_driver_card.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_vehicle_card.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/quantity_input_formatter.dart';
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
  final TextEditingController _customerController =
      AuthRepo.role == "customer"
          ? TextEditingController(text: AuthRepo.user)
          : TextEditingController();
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
  List<XFile>? _vehicleImageFiles;
  List<XFile>? _driverImageFiles;
  bool _showVehicleImages = false;
  bool _showDriverImages = false;

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
      _fuelRefillController.getDriverVehicleDropdown(AuthRepo.customerId);
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
        await _uploadImages();
        showSuccessSnack("Refill entry Successfull!");
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.fuelRefillListScreen,
          removeUntilPageName: Screenroutes.fuelRefillListScreen,
        );
      } else {
        showErrorSnack("Error uploading Refill data");
      }
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(bool isVehicle) async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        if (isVehicle) {
          _vehicleImageFiles = [...?_vehicleImageFiles, ...pickedFiles];
        } else {
          _driverImageFiles = [...?_driverImageFiles, ...pickedFiles];
        }
      });
    }
  }

  Future<void> _takePicture(bool isVehicle) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        if (isVehicle) {
          _vehicleImageFiles = [...?_vehicleImageFiles, pickedFile];
        } else {
          _driverImageFiles = [...?_driverImageFiles, pickedFile];
        }
      });
    }
  }

  Future<void> _uploadImages() async {
    final _refillId = _fuelRefillController.refillId;
    if (_refillId == null) {
      print('Refill ID is null');
      return;
    }

    List<MultipartFile> allImages = [];

    // Combine vehicle and driver images
    if (_vehicleImageFiles != null && _vehicleImageFiles!.isNotEmpty) {
      for (var file in _vehicleImageFiles!) {
        allImages.add(await MultipartFile.fromFile(file.path));
      }
    }

    if (_driverImageFiles != null && _driverImageFiles!.isNotEmpty) {
      for (var file in _driverImageFiles!) {
        allImages.add(await MultipartFile.fromFile(file.path));
      }
    }

    if (allImages.isEmpty) {
      print('No images selected');
      return;
    }

    bool isSuccess = await _fuelRefillController.uploadRefillImages(
      allImages,
      _refillId.toString(),
    );
    if (isSuccess) {
      showSuccessSnack('Images uploaded successfully');
    } else {
      showErrorSnack('Error uploading images');
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
                          File(imageFiles[currentIndex].path),
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

  Widget _buildImageSection(String title, List<XFile>? images, bool isVehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title Pictures',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        images != null && images.isNotEmpty
            ? GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showFullScreenImage(context, images, index);
                      },
                      child: Image.file(
                        File(images[index].path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isVehicle) {
                            _vehicleImageFiles!.removeAt(index);
                          } else {
                            _driverImageFiles!.removeAt(index);
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                );
              },
            )
            : Text('No $title images selected.'),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImages(isVehicle),
              icon: Icon(
                Icons.photo_library,
                color: Appcolors.textWhiteColor(context),
              ),
              label: Text(
                'Gallery',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Appcolors.textWhiteColor(context),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _takePicture(isVehicle),
              icon: Icon(
                Icons.camera_alt,
                color: Appcolors.textWhiteColor(context),
              ),
              label: Center(
                child: Text(
                  'Camera',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Appcolors.textWhiteColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
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

        return Scaffold(
          appBar: AppBar(title: Text('Fuel Entry'), centerTitle: true),
          body:
              unitData == null ||
                      productData == null ||
                      customerData == null ||
                      refillData == null ||
                      vehicleData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
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
                                    (filter, infiniteScrollProps) => refillData,
                                itemAsString: (item) => item['serial_no'] ?? '',
                                compareFn: (
                                  Map<String, dynamic> item1,
                                  Map<String, dynamic> item2,
                                ) {
                                  return item1['id'] == item2['id'];
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
                                              refill['id'] == _selectedRefillId,
                                        )
                                        : null,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a Refilling Unit';
                                  }
                                  return null;
                                },
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Select Refilling Unit',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              AuthRepo.role == "customer"
                                  ? TextFormField(
                                    readOnly: true,
                                    controller: _customerController,
                                    decoration: InputDecoration(
                                      labelText: 'Customer',
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
                                  )
                                  : DropdownSearch<Map<String, dynamic>>(
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
                                      return item1['id'] == item2['id'];
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
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _vehicleController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Number',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.arrow_forward_ios),
                                ),
                                onTap: () async {
                                  final selectedVehicle = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => FuelRefillVehicleCard(
                                            vehicles: vehicleData ?? [],
                                          ),
                                    ),
                                  );

                                  if (selectedVehicle != null) {
                                    setState(() {
                                      _selectedVehicleId =
                                          selectedVehicle['id'];
                                      _vehicleController.text =
                                          selectedVehicle['plate_no'];
                                      _showVehicleImages = true;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a vehicle';
                                  }
                                  return null;
                                },
                              ),
                              if (_showVehicleImages)
                                _buildImageSection(
                                  'Vehicle',
                                  _vehicleImageFiles,
                                  true,
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
                                  return null;
                                },
                                inputFormatters: [QuantityInputFormatter()],
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                readOnly: true,
                                controller: _unitController,
                                decoration: InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                readOnly: true,
                                controller: _productController,
                                decoration: InputDecoration(
                                  labelText: 'Product',
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _driverController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Driver Name',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.arrow_forward_ios),
                                ),
                                onTap: () async {
                                  final selectedDriver = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => FuelRefillDriverCard(
                                            drivers: driverData ?? [],
                                          ),
                                    ),
                                  );

                                  if (selectedDriver != null) {
                                    setState(() {
                                      _selectedDriverId = selectedDriver['id'];
                                      _driverController.text =
                                          selectedDriver['Name'];
                                      _showDriverImages = true;
                                    });
                                  }
                                },
                              ),
                              if (_showDriverImages)
                                _buildImageSection(
                                  'Driver',
                                  _driverImageFiles,
                                  false,
                                ),
                              SizedBox(height: 20),
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
                            onPressed: () async {
                              _postRefillData();
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
