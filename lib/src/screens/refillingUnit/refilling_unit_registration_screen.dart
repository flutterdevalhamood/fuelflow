import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_colors.dart';
import '../../util/app_navigation.dart';
import '../../util/app_sizes.dart';

class RefillingUnitRegistrationScreen extends StatefulWidget {
  const RefillingUnitRegistrationScreen({super.key});

  @override
  State<RefillingUnitRegistrationScreen> createState() =>
      _RefillingUnitRegistrationScreenState();
}

class _RefillingUnitRegistrationScreenState
    extends State<RefillingUnitRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final dropDownKey = GlobalKey<DropdownSearchState>();

  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _capacityUnitController = TextEditingController();

  final TextEditingController _reasonController = TextEditingController();
  late RefillingUnitController _refillingUnitController;
  int? _selectedCapacityUnitId;
  int? _selectedDriverId;
  int? _selectedVehicleId;
  int? _selectedProductId;
  List<XFile>? _imageFiles;
  bool _isRegistrationComplete = false;

  int? _selectedType = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refillingUnitController = Provider.of<RefillingUnitController>(
        context,
        listen: false,
      );
      _refillingUnitController.getRefillUnitDropDown();
    });
    super.initState();
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _capacityController.dispose();
    _capacityUnitController.dispose();
    _driverController.dispose();
    _vehicleController.dispose();
    _productController.dispose();
    super.dispose();
  }

  Future<void> _postRefillData() async {
    if (_formKey.currentState!.validate()) {
      bool isSuccess = await _refillingUnitController.postRefillUnitData(
        type: _selectedType,
        serialNo: _serialNumberController.text.trim(),
        vehicleId: _selectedVehicleId,
        driverId: _selectedDriverId,
        productId: _selectedProductId,
        capacity: _capacityController.text.trim(),
        capacityUnitId: _selectedCapacityUnitId,
      );
      if (isSuccess) {
        showSuccessSnack("Refill Unit entry Successfull! Add images now...");
        setState(() {
          _isRegistrationComplete = true;
        });
      } else {
        showErrorSnack("Error uploading Refill Unit data");
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
    final _refillId = _refillingUnitController.refillUnitId;
    if (_imageFiles == null || _imageFiles!.isEmpty) {
      print('No images selected');
      return;
    }

    List<MultipartFile> multipartFiles = [];
    for (var file in _imageFiles!) {
      multipartFiles.add(await MultipartFile.fromFile(file.path));
    }

    if (_refillId != null) {
      bool isSuccess = await _refillingUnitController.uploadRefillUnitImages(
        multipartFiles,
        _refillId.toString(),
      );
      if (isSuccess) {
        showSuccessSnack('Image uploaded successfully');
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.refillingUnitListScreen,
          removeUntilPageName: Screenroutes.refillingUnitListScreen,
        );
      } else {
        showErrorSnack('Error uploading image');
      }
    } else {
      print('Refill Unit ID is null');
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
    return Consumer<RefillingUnitController>(
      builder: (context, refillUnitController, child) {
        final unitData = refillUnitController.unitData;
        final driverData = refillUnitController.driverData;
        final productData = refillUnitController.productData;
        final vehicleData = refillUnitController.vehicleData;
        print('unitDatasss $unitData');
        print('driverData $driverData');
        print('vehicleData $vehicleData');

        return Scaffold(
          appBar: AppBar(title: Text('Fuel Unit Entry'), centerTitle: true),
          body:
              unitData == null || driverData == null || vehicleData == null
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
                                Text(
                                  'Select Type',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio(
                                      value: 0,
                                      groupValue: _selectedType,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedType = value!;
                                        });
                                      },
                                    ),
                                    Text('Vehicle'),
                                    Radio(
                                      value: 1,
                                      groupValue: _selectedType,
                                      onChanged: (int? value) {
                                        setState(() {
                                          _selectedType = value!;
                                        });
                                      },
                                    ),
                                    Text('Tank'),
                                  ],
                                ),
                                TextFormField(
                                  controller: _serialNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Serial Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter Serial Number';
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                DropdownSearch<Map<String, dynamic>>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    fit: FlexFit.tight,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Search Vehicle...',
                                      ),
                                    ),
                                  ),
                                  items:
                                      (filter, infiniteScrollProps) =>
                                          vehicleData,
                                  itemAsString:
                                      (item) => item['plate_no'] ?? '',
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
                                        _selectedVehicleId = newValue['id'];
                                        _vehicleController.text =
                                            newValue['plate_no'];
                                      });
                                    }
                                  },
                                  selectedItem:
                                      _selectedVehicleId != null
                                          ? vehicleData.firstWhere(
                                            (vehicle) =>
                                                vehicle['id'] ==
                                                _selectedVehicleId,
                                          )
                                          : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a Vehicle';
                                    }
                                    return null;
                                  },
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle',
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
                                        hintText: 'Search Driver...',
                                      ),
                                    ),
                                  ),
                                  items:
                                      (filter, infiniteScrollProps) =>
                                          driverData,
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
                                        _selectedDriverId = newValue['id'];
                                        _driverController.text =
                                            newValue['Name'];
                                      });
                                    }
                                  },
                                  selectedItem:
                                      _selectedDriverId != null
                                          ? driverData.firstWhere(
                                            (driver) =>
                                                driver['id'] ==
                                                _selectedDriverId,
                                          )
                                          : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a Driver';
                                    }
                                    return null;
                                  },
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Driver',
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
                                        hintText: 'Search Product Name...',
                                      ),
                                    ),
                                  ),
                                  items:
                                      (filter, infiniteScrollProps) async =>
                                          productData ?? [],
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
                                        _selectedProductId = newValue['id'];
                                        _productController.text =
                                            newValue['Name'];
                                      });
                                    }
                                  },
                                  selectedItem:
                                      _selectedProductId != null
                                          ? productData?.firstWhere(
                                            (product) =>
                                                product['id'] ==
                                                _selectedProductId,
                                          )
                                          : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a Product ID';
                                    }
                                    return null;
                                  },
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Product Name',
                                      border: OutlineInputBorder(),
                                    ),
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
