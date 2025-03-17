import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../../util/app_sizes.dart';
import '../../util/snack.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isRegistrationComplete = false; // Track registration completion
  String? _vehicleId;

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

  // Image picker
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
    final _vehicleId = _vehicleController.vehicleData?[0]['id'];
    print('aaaaa $_vehicleId');
    if (_imageFiles == null || _imageFiles!.isEmpty) {
      print('No images selected');
      return;
    }

    List<MultipartFile> multipartFiles = [];
    for (var file in _imageFiles!) {
      multipartFiles.add(await MultipartFile.fromFile(file.path));
    }

    if (_vehicleId != null) {
      bool isSuccess = await _vehicleController.uploadVehiclePictures(
        multipartFiles,
        _vehicleId.toString(),
      );
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
      print('Vehicle ID is null');
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

  Future<void> _registerVehicle() async {
    // if (_formKey.currentState!.validate()) {
    bool isSuccess = await _vehicleController.registerVehicle(
      _plateNumberController.text.trim(),
      _capacityController.text.trim(),
      _noteController.text.trim(),
      _selectedTypeId,
      _selectedCapacityUnitId,
      _selectedCustomerId,
    );
    if (isSuccess) {
      showSuccessSnack("Customer registered successfully!");
      _vehicleController.getVehicleData();
      // Navigator.pop(context, true);
    } else {
      showErrorSnack("Error registering customer");
    }
    setState(() {
      _isRegistrationComplete = true;
    });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final _vehicleController = Provider.of<VehicleController>(context);
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
                        child: Column(
                          children: [
                            if (!_isRegistrationComplete) ...[
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Customer',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedCustomerId,
                                items:
                                    (customerData ?? []).map((item) {
                                      return DropdownMenuItem<int>(
                                        value: item['id'],
                                        child: Text(item['Name']),
                                        onTap: () {
                                          setState(() {
                                            _selectedCustomerId = item['id'];
                                          });
                                        },
                                      );
                                    }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedCustomerId = newValue;
                                    // _customerController.text = newValue ?? '';
                                  });
                                },
                              ),
                              SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedType,
                                items:
                                    (vehicleTypeData ?? []).map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item['Name'],
                                        child: Text(item['Name']),
                                        onTap: () {
                                          setState(() {
                                            _selectedTypeId = item['id'];
                                          });
                                        },
                                      );
                                    }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedType = newValue;
                                    _typeController.text = newValue ?? '';
                                  });
                                },
                              ),
                              SizedBox(height: 20),

                              TextField(
                                controller: _plateNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Plate Number',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _capacityController,
                                      decoration: InputDecoration(
                                        labelText: 'Capacity',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<int>(
                                      decoration: InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
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
                                          // _capacityUnitController.text =
                                          //     newValue ?? '';
                                        });
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
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
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
                                      color: Appcolors.textWhiteColor(context),
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
                                      color: Appcolors.textWhiteColor(context),
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

                      // Save Button at the bottom, placed inside Stack
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
