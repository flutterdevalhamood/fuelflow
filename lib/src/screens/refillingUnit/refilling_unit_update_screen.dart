import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_sizes.dart';
import 'package:sample/src/util/quantity_input_formatter.dart';
import 'package:sample/src/util/snack.dart';

import '../../util/app_routes.dart';

class RefillingUnitUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const RefillingUnitUpdateScreen({super.key, required this.data});

  @override
  _RefillingUnitUpdateScreenState createState() =>
      _RefillingUnitUpdateScreenState();
}

class _RefillingUnitUpdateScreenState extends State<RefillingUnitUpdateScreen> {
  late TextEditingController _driverController;
  late TextEditingController _serialNumberController;
  late TextEditingController _vehicleController;
  late TextEditingController _capacityController;
  late TextEditingController _capacityUnitController;

  // Dropdown values
  String? _selectedType;
  String? _selectedCapacityUnit;
  String? _selectedVehicle;
  String? _selectedProduct;
  String? _selectedDriver;
  int? _selectedVehicleId;
  int? _selectedProductId;
  int? _selectedDriverId;
  int? _selectedTypeId;
  int? _selectedCapacityUnitId;
  int? id;
  bool _isAddImagesClicked = false;
  List<XFile>? _imageFiles = [];

  // Image picker
  final ImagePicker _picker = ImagePicker();
  int? index;

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

    // Initialize controllers with existing data
    _vehicleController = TextEditingController(
      text: widget.data['vehicle']?['plate_no'] ?? '',
    );
    _driverController = TextEditingController(
      text: widget.data['driver']?['Name'] ?? '',
    );
    _serialNumberController = TextEditingController(
      text: widget.data['serial_no'] ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.data['capacity'] ?? '',
    );
    _capacityUnitController = TextEditingController(
      text: widget.data['vehicle_capacity_unit']?['Name'] ?? '',
    );

    _selectedCapacityUnit = widget.data['capacity_unit']?['Name'];
    _selectedVehicle = widget.data['vehicle']?['plate_no'];
    _selectedDriver = widget.data['driver']?['Name'];
    _selectedProduct = widget.data['product']?['Name'];
    _selectedType = widget.data['type'];

    // Parse IDs safely
    _selectedCapacityUnitId = _parseId(widget.data['capacity_unit']?['id']);
    _selectedVehicleId = _parseId(widget.data['vehicle_id']);
    _selectedDriverId = _parseId(widget.data['driver_id']);
    _selectedProductId = _parseId(widget.data['product']?['id']);
    id = widget.data['id'];

    // Parse type ID specifically - could be an int directly or a string representation
    if (widget.data['type'] is int) {
      _selectedTypeId = widget.data['type'];
    } else if (widget.data['type'] is String) {
      _selectedTypeId = int.tryParse(widget.data['type']) ?? null;
    }

    // Should match above
    id = widget.data['id'];
  }

  // Helper method to safely parse IDs that might be various types
  int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  late RefillingUnitController _refillingUnitController;

  @override
  void dispose() {
    _serialNumberController.dispose();
    _capacityController.dispose();
    _capacityUnitController.dispose();
    _vehicleController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final serialNumber = _serialNumberController.text.trim();
    final capacity = _capacityController.text.trim();

    if (id != null) {
      await _refillingUnitController.editRefillUnitData(
        id,
        _selectedTypeId,
        serialNumber,
        _selectedVehicleId,
        _selectedDriverId,
        capacity,
        _selectedCapacityUnitId,
        _selectedProductId,
      );
      showSuccessSnack('Refill Unit updated successfully');
      Navigator.pop(context, true);
    } else {
      showErrorSnack('Error updating data');
    }
  }

  Future<void> _deleteRefillingUnitImages(int? imageId) async {
    final refillingUnitData = widget.data;
    if (refillingUnitData['id'] != null) {
      await _refillingUnitController.deleteRefillUnitImagesById(imageId);
      showSuccessSnack("Refilling Unit deleted successfully");
      Navigator.pop(context, true);
    } else {
      showErrorSnack("Error deleting images");
    }
  }

  void showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: GestureDetector(
              onTap: NavigationService().popNavigation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
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
    final _vehicleId = _refillingUnitController.refillUnitData?[0]['id'];
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
      bool isSuccess = await _refillingUnitController.uploadRefillUnitImages(
        multipartFiles,
        _vehicleId.toString(),
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
      print('Vehicle ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final refillUnitData = widget.data;
    return Consumer<RefillingUnitController>(
      builder: (context, refillUnitController, child) {
        final vehicleData = refillUnitController.vehicleData;
        final unitData = refillUnitController.unitData;
        final productData = refillUnitController.productData;
        final driverData = refillUnitController.driverData;

        return Scaffold(
          appBar: AppBar(title: Text('Edit Refill Unit')),
          body:
              vehicleData == null || unitData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (!_isAddImagesClicked) ...[
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
                                  Radio<int>(
                                    value: 0,
                                    groupValue: _selectedTypeId,
                                    onChanged: (int? value) {
                                      setState(() {
                                        _selectedTypeId = value;
                                      });
                                    },
                                  ),
                                  Text('Vehicle'),
                                  Radio<int>(
                                    value: 1,
                                    groupValue: _selectedTypeId,
                                    onChanged: (int? value) {
                                      setState(() {
                                        _selectedTypeId = value;
                                      });
                                    },
                                  ),
                                  Text('Tank'),
                                ],
                              ),
                              TextField(
                                readOnly: true,
                                controller: _serialNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Serial Number',
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

                              // Vehicle Dropdown
                              if (vehicleData != null)
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Vehicle',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _findValidDropdownValue(
                                    _selectedVehicleId,
                                    vehicleData,
                                  ),
                                  hint: Text('Select Vehicle'),
                                  items:
                                      vehicleData.map<DropdownMenuItem<int>>((
                                        item,
                                      ) {
                                        return DropdownMenuItem<int>(
                                          value: item['id'],
                                          child: Text(
                                            item['plate_no'] ?? 'Unknown',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedVehicleId = newValue;
                                    });
                                  },
                                ),
                              SizedBox(height: 20),

                              // Driver Dropdown
                              if (driverData != null)
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Driver',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _findValidDropdownValue(
                                    _selectedDriverId,
                                    driverData,
                                  ),
                                  hint: Text('Select Driver'),
                                  items:
                                      driverData.map<DropdownMenuItem<int>>((
                                        item,
                                      ) {
                                        return DropdownMenuItem<int>(
                                          value: item['id'],
                                          child: Text(
                                            item['Name'] ?? 'Unknown',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedDriverId = newValue;
                                    });
                                  },
                                ),
                              SizedBox(height: 20),

                              // Product Dropdown
                              if (productData != null)
                                DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Product',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _findValidDropdownValue(
                                    _selectedProductId,
                                    productData,
                                  ),
                                  hint: Text('Select Product'),
                                  items:
                                      productData.map<DropdownMenuItem<int>>((
                                        item,
                                      ) {
                                        return DropdownMenuItem<int>(
                                          value: item['id'],
                                          child: Text(
                                            item['Name'] ?? 'Unknown',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedProductId = newValue;
                                    });
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
                                        labelText: 'Capacity',
                                        border: OutlineInputBorder(),
                                      ),
                                      inputFormatters: [
                                        QuantityInputFormatter(),
                                      ],
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
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
                                      value: _findValidDropdownValue(
                                        _selectedCapacityUnitId,
                                        unitData,
                                      ),
                                      hint: Text('Unit'),
                                      items:
                                          unitData.map<DropdownMenuItem<int>>((
                                            item,
                                          ) {
                                            return DropdownMenuItem<int>(
                                              value: item['id'],
                                              child: Text(
                                                item['Name'] ?? 'Unknown',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (newValue) {
                                        setState(() {
                                          _selectedCapacityUnitId = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),
                              if (refillUnitData['refiling_unit_images'] !=
                                      null &&
                                  refillUnitData['refiling_unit_images']
                                      .isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        refillUnitData['refiling_unit_images']
                                            .length,
                                    itemBuilder: (context, index) {
                                      final image =
                                          refillUnitData['refiling_unit_images'][index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showFullScreenImage(
                                                  context,
                                                  image['Title'],
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  image['Title'],
                                                  width: 150,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      width: 150,
                                                      color:
                                                          Colors
                                                              .grey[300], // Placeholder background
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey[600],
                                                      ), // Fallback icon
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showDeleteConfirmationDialog(
                                                    image['id'],
                                                  );
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isAddImagesClicked = true;
                                  });
                                },
                                icon: Icon(
                                  Icons.photo_library,
                                  color: Appcolors.textWhiteColor(context),
                                ),
                                label: Text(
                                  'Add Images',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    color: Appcolors.textWhiteColor(context),
                                  ),
                                ),
                              ),
                            ] else ...[
                              if (refillUnitData['refiling_unit_images'] !=
                                      null &&
                                  refillUnitData['refiling_unit_images']
                                      .isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        refillUnitData['refiling_unit_images']
                                            .length,
                                    itemBuilder: (context, index) {
                                      final image =
                                          refillUnitData['refiling_unit_images'][index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showFullScreenImage(
                                                  context,
                                                  image['Title'],
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  image['Title'],
                                                  width: 150,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      width: 150,
                                                      color:
                                                          Colors
                                                              .grey[300], // Placeholder background
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey[600],
                                                      ), // Fallback icon
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showDeleteConfirmationDialog(
                                                    image['id'],
                                                  );
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickImages,
                                    icon: Icon(
                                      Icons.photo_library,
                                      color: Appcolors.textWhiteColor(context),
                                    ),
                                    label: Text(
                                      'Gallery',
                                      style: TextStyle(
                                        color: Appcolors.textWhiteColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: Appcolors.textWhiteColor(context),
                                    ),
                                    label: Text(
                                      'Camera',
                                      style: TextStyle(
                                        color: Appcolors.textWhiteColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              if (_imageFiles != null &&
                                  _imageFiles!.isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _imageFiles!.length,
                                    itemBuilder: (context, index) {
                                      final image = _imageFiles![index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(image.path),
                                                width: 150,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _removeImage(index);
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _uploadImages,
                                child: Text(
                                  'Upload Images',
                                  style: TextStyle(
                                    color: Appcolors.textWhiteColor(context),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isAddImagesClicked = false;
                                  });
                                },
                                child: Text(
                                  'Back to Form',
                                  style: TextStyle(
                                    color: Appcolors.textWhiteColor(context),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(
                              height: 80,
                            ), // Extra space for the Save button
                          ],
                        ),
                      ),
                      if (!_isAddImagesClicked)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            width: double.infinity,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          saveEditedData();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 50,
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          minimumSize: Size(
                                            double.infinity,
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Save',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.copyWith(
                                            color: Appcolors.textWhiteColor(
                                              context,
                                            ),
                                            fontSize: AppWidgetSizes.fontSize18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
        );
      },
    );
  }

  // Helper method to find a valid dropdown value
  int? _findValidDropdownValue(int? currentValue, List<dynamic> items) {
    // If the current value exists in the items, return it
    if (currentValue != null) {
      bool valueExists = items.any((item) => item['id'] == currentValue);
      if (valueExists) {
        return currentValue;
      }
    }
    // Otherwise return null (dropdown will show hint)
    return null;
  }

  // Remove image from selected images
  void _removeImage(int index) {
    setState(() {
      _imageFiles!.removeAt(index);
    });
  }

  void _showDeleteConfirmationDialog(int imageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Image'),
          content: Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRefillingUnitImages(imageId);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
