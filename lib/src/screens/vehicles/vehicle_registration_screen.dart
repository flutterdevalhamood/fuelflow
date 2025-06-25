import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _selectedType;
  String? _selectedCapacityUnit;
  String? _selectedCustomer;
  int? _selectedTypeId;
  int? _selectedCapacityUnitId;
  int? _selectedCustomerId;
  late VehicleController _vehicleController;
  List<XFile>? _imageFiles;
  bool _isRegistrationComplete = false;
  String? _vehicleId;
  bool _isSubmitClicked = false;
  bool _isUploading = false;
  bool _isRegisteringForCustomer = false;
  final ImagePicker _picker = ImagePicker();

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
    super.dispose();
  }

  void _resetForm() {
    _plateNumberController.clear();
    _capacityController.clear();
    _noteController.clear();
    _typeController.clear();
    _customerController.clear();
    _capacityUnitController.clear();
    _selectedTypeId = null;
    _selectedCapacityUnitId = null;
    _selectedCustomerId = null;
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = [...?_imageFiles, ...pickedFiles];
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFiles = [...?_imageFiles, pickedFile];
        });
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
      showErrorSnack("Failed to take picture");
    }
  }

  Future<void> _uploadImages() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
    });
    final _vehicleId = _vehicleController.vehicleData?[0]['id'];
    if (_imageFiles == null || _imageFiles!.isEmpty) {
      setState(() {
        _isUploading = false;
      });
      showErrorSnack('Please select at least one image');
      return;
    }
    try {
      List<MultipartFile> multipartFiles = [];
      for (var file in _imageFiles!) {
        multipartFiles.add(await MultipartFile.fromFile(file.path));
      }

      if (_vehicleId != null) {
        bool isSuccess = await _vehicleController.uploadVehiclePictures(
          multipartFiles,
          _vehicleId.toString(),
        );
        setState(() {
          _isUploading = false;
        });
        if (isSuccess) {
          showSuccessSnack('Image uploaded successfully');
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.vehicleList,
            removeUntilPageName: Screenroutes.vehicleList,
          );
        } else {
          showErrorSnack('Error uploading image');
        }
      } else {
        setState(() {
          _isUploading = false;
        });
        showErrorSnack('Vehicle ID not found');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
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
        );
      } else {
        isSuccess = await _vehicleController.registerVehicle(
          _plateNumberController.text.trim(),
          _capacityController.text.trim(),
          _noteController.text.trim(),
          _selectedTypeId,
          _selectedCapacityUnitId ?? 0,
          AuthRepo.customerId, // No customer ID for self registration
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
      } else {
        showErrorSnack("Error registering vehicle");
      }
      setState(() {
        _isRegistrationComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleController>(
      builder: (context, vehicleController, child) {
        final vehicleTypeData = vehicleController.vehicleTypeData;
        final unitData = vehicleController.unitData;
        final customerData = vehicleController.customerData;

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

                              if (!_isRegistrationComplete) ...[
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
                                        setState(() {
                                          _selectedCustomerId = newValue['id'];
                                          _customerController.text =
                                              newValue['serial_no'];
                                        });
                                      }
                                    },
                                    selectedItem:
                                        _selectedCustomerId != null
                                            ? customerData.firstWhere(
                                              (refill) =>
                                                  refill['id'] ==
                                                  _selectedCustomerId,
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
                                                vehicle['id'] ==
                                                _selectedTypeId,
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
                                          MediaQuery.of(context).size.width *
                                          0.4,
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
                                      onPressed: _pickImages,
                                      icon: Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Gallery',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade900,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _takePicture,
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Camera',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade900,
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
                            onPressed:
                                _isSubmitClicked || _isUploading
                                    ? null
                                    : () async {
                                      !_isRegistrationComplete
                                          ? _registerVehicle()
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
                              backgroundColor: Colors.blue.shade900,
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child:
                                _isSubmitClicked || _isUploading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      !_isRegistrationComplete
                                          ? _isRegisteringForCustomer
                                              ? 'Register for Customer'
                                              : 'Register for Myself'
                                          : 'Save',
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
