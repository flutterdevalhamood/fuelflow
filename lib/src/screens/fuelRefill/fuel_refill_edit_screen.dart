import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/fuel_refill_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_sizes.dart';

class EditFuelRefillScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditFuelRefillScreen({super.key, required this.data});

  @override
  _EditFuelRefillScreenState createState() => _EditFuelRefillScreenState();
}

class _EditFuelRefillScreenState extends State<EditFuelRefillScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _plateNumberController;
  late TextEditingController _productNameController;
  late TextEditingController _driverNameController;
  late TextEditingController _qtyController;

  // Dropdown values
  String? _selectedCapacityUnit;
  String? _selectedCustomer;
  String? _selectedProduct;
  int? _selectedCustomerId;
  int? _selectedCapacityUnitId;
  int? _selectedProductId;
  bool _isAddImagesClicked = false;
  List<XFile>? _imageFiles;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  late FuelRefillController _fuelRefillController;
  int? index;

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

    // Initialize controllers with existing data

    _customerNameController = TextEditingController(
      text: widget.data['customer']?['name'] ?? '',
    );
    _plateNumberController = TextEditingController(
      text: widget.data['vehicle']?['plate_no'] ?? '',
    );
    _productNameController = TextEditingController(
      text: widget.data['product']?['Name'],
    );
    _qtyController = TextEditingController(text: widget.data['qty']);

    _driverNameController = TextEditingController(
      text: widget.data['driver']?['Name'],
    );

    _selectedCapacityUnit = widget.data['vehicle_capacity_unit']?['Name'];
    _selectedCustomer = widget.data['customer']?['Name'];
    _selectedProduct = widget.data['product']?['Name'];

    _selectedCapacityUnitId = widget.data['vehicle_capacity_unit']?['id'];
    _selectedCustomerId = widget.data['customer']?['id'];
    _selectedProductId = widget.data['product']?['id'];

    print('_selectedCapacityUnit $_selectedCapacityUnit');
    // _loadImages();
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _customerNameController.dispose();
    _productNameController.dispose();
    _driverNameController.dispose();
    super.dispose();
  }

  // Future<void> saveEditedData() async {
  //   final id = widget.data['id'];
  //   final plateNumber = _plateNumberController.text.trim();
  //   final description = _noteController.text.trim();
  //   final capacity = _capacityController.text.trim();
  //
  //   if (id != null) {
  //     await _vehicleController.editVehicleData(
  //       id,
  //       plateNumber,
  //       description,
  //       capacity,
  //       _selectedCapacityUnitId,
  //       _selectedCustomerId,
  //     );
  //     showSuccessSnack('Vehicle updated successfully');
  //     Navigator.pop(context, true);
  //   } else {
  //     showErrorSnack('Error updating data');
  //   }
  // }

  // Future<void> _deleteImages(int? ImageId) async {
  //   final vehicle = widget.data;
  //   if (vehicle['id'] != null) {
  //     await _vehicleController.deleteImagesById(ImageId);
  //     showSuccessSnack("Vehicle deleted successfully");
  //     Navigator.pop(context, true);
  //   } else {
  //     showErrorSnack("Error deleting images");
  //   }
  // }

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

  // Future<void> _uploadImages() async {
  //   final _vehicleId = _vehicleController.vehicleData?[0]['id'];
  //   print('aaaaa $_vehicleId');
  //   if (_imageFiles == null || _imageFiles!.isEmpty) {
  //     print('No images selected');
  //     return;
  //   }
  //
  //   List<MultipartFile> multipartFiles = [];
  //   for (var file in _imageFiles!) {
  //     multipartFiles.add(await MultipartFile.fromFile(file.path));
  //   }
  //
  //   if (_vehicleId != null) {
  //     bool isSuccess = await _vehicleController.uploadVehiclePictures(
  //       multipartFiles,
  //       _vehicleId.toString(),
  //     );
  //     if (isSuccess) {
  //       showSuccessSnack('Image uploaded successfully');
  //       NavigationService().pushAndRemoveUntilNavigation(
  //         Screenroutes.vehicleList,
  //         removeUntilPageName: Screenroutes.vehicleList,
  //       );
  //     } else {
  //       showErrorSnack('Error uploading image');
  //     }
  //   } else {
  //     print('Vehicle ID is null');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final fuelRefillData = widget.data;
    print('fuelRefillDataa $fuelRefillData');
    return Consumer<FuelRefillController>(
      builder: (context, fuelRefillController, child) {
        final vehicleTypeData = fuelRefillController.vehicleTypeData;
        final unitData = fuelRefillController.unitData;
        final customerDropdownData = fuelRefillController.customerData;
        final productData = fuelRefillController.productData;

        return Scaffold(
          appBar: AppBar(title: Text('Edit Fuel Refill Details')),
          body:
          // vehicleTypeData == null || unitData == null
          //     ? Center(child: CircularProgressIndicator())
          //     :
          Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!_isAddImagesClicked) ...[
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Customer',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCustomerId,
                        items:
                            (customerDropdownData ?? []).map((item) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(item['name'].toString()),
                                onTap: () {
                                  setState(() {
                                    _selectedCustomerId = item['id'];
                                  });
                                },
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCustomerId = newValue;
                            // _customerNameController.text =
                            //     newValue ?? '';
                          });
                        },
                      ),

                      SizedBox(height: 20),
                      TextField(
                        readOnly: true,
                        controller: _plateNumberController,
                        decoration: InputDecoration(
                          labelText: 'Plate Number',
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
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _qtyController,
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
                                          _selectedCapacityUnitId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
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
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'product',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProductId,
                        items:
                            (productData ?? []).map((item) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(item['Name'].toString()),
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = item['id'];
                                  });
                                },
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedProductId = newValue;
                            // _customerNameController.text =
                            //     newValue ?? '';
                          });
                        },
                      ),

                      SizedBox(height: 20),
                      if (fuelRefillData['refil_images'] != null &&
                          fuelRefillData['refil_images'].isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fuelRefillData['refil_images'].length,
                            itemBuilder: (context, index) {
                              final image =
                                  fuelRefillData['refil_images'][index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
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
                                        borderRadius: BorderRadius.circular(10),
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
                      if (fuelRefillData['refil_images'] != null &&
                          fuelRefillData['refil_images'].isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fuelRefillData['refil_images'].length,
                            itemBuilder: (context, index) {
                              final image =
                                  fuelRefillData['refil_images'][index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
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
                                        borderRadius: BorderRadius.circular(10),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                color: Appcolors.textWhiteColor(context),
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
                                color: Appcolors.textWhiteColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (_imageFiles != null && _imageFiles!.isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles!.length,
                            itemBuilder: (context, index) {
                              final image = _imageFiles![index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
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
                        onPressed: () {},
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
                    SizedBox(height: 80), // Extra space for the Save button
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
                                  // saveEditedData();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: Size(double.infinity, 10),
                                ),
                                child: Text(
                                  'Save',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    color: Appcolors.textWhiteColor(context),
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
  // Save updated data

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
                // _deleteImages(imageId);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
