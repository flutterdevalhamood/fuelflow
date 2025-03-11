import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/app_sizes.dart';
import 'package:sample/src/util/snack.dart';

import '../../providers/vehicle_controller.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditVehicleScreen({super.key, required this.data});

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _typeController;
  late TextEditingController _plateNumberController;
  late TextEditingController _capacityController;
  late TextEditingController _capacityUnitController;
  late TextEditingController _noteController;

  // Dropdown values
  String? _selectedType;
  String? _selectedCapacityUnit;
  String? _selectedCustomer;
  int? _selectedCustomerId;
  int? _selectedTypeId;
  int? _selectedCapacityUnitId;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  late VehicleController _vehicleController;
  int? index;

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

    // Initialize controllers with existing data

    _customerNameController = TextEditingController(
      text: widget.data['customer']?['Name'] ?? '',
    );
    _typeController = TextEditingController(
      text: widget.data['type']?['Name'] ?? '',
    );
    _plateNumberController = TextEditingController(
      text: widget.data['plate_no'] ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.data['capacity'] ?? '',
    );
    _capacityUnitController = TextEditingController(
      text: widget.data['vehicle_capacity_unit']?['Name'] ?? '',
    );
    _noteController = TextEditingController(
      text: widget.data['description'] ?? '',
    );

    _selectedType = widget.data['type']?['Name'];
    _selectedCapacityUnit = widget.data['vehicle_capacity_unit']?['Name'];
    _selectedCustomer = widget.data['customer']['Name'];

    _selectedTypeId = widget.data['type']?['id'];
    _selectedCapacityUnitId = widget.data['vehicle_capacity_unit']?['id'];
    _selectedCustomerId = widget.data['customer']?['id'];

    print('_selectedType $_selectedType');
    print('_selectedCapacityUnit $_selectedCapacityUnit');
    // _loadImages();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _plateNumberController.dispose();
    _capacityController.dispose();
    _capacityUnitController.dispose();
    _noteController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final id = widget.data['id'];
    final plateNumber = _plateNumberController.text.trim();
    final description = _noteController.text.trim();
    final capacity = _capacityController.text.trim();

    if (id != null) {
      await _vehicleController.editVehicleData(
        id,
        plateNumber,
        description,
        capacity,
        _selectedTypeId,
        _selectedCapacityUnitId,
        _selectedCustomerId,
      );
      showSuccessSnack('Vehicle updated successfully');
      Navigator.pop(context, true);
    } else {
      showErrorSnack('Error updating data');
    }
  }

  // Future<void> _loadImages() async {
  //   final appDir = await getApplicationDocumentsDirectory();
  //   final List<String> imageFileNames = List<String>.from(
  //     widget.data['images'] ?? [],
  //   );
  //
  //   _selectedImages = [];
  //   for (final fileName in imageFileNames) {
  //     final file = File('${appDir.path}/$fileName');
  //     if (await file.exists()) {
  //       _selectedImages.add(file); // Add the File object
  //     }
  //   }
  //   setState(() {});
  // }

  // Future<void> _saveData() async {
  //   final List<String> imageFileNames =
  //       _selectedImages.map((file) => file.path.split('/').last).toList();
  //   final vehicleData = {
  //     'type': _typeController.text,
  //     'plateNumber': _plateNumberController.text,
  //     'capacity': _capacityController.text,
  //     'capacityUnit': _capacityUnitController.text,
  //     'note': _noteController.text,
  //     'images': imageFileNames,
  //   };

  // final vehicleProvider = Provider.of<VehicleProvider>(
  //   context,
  //   listen: false,
  // );
  // await vehicleProvider.addOrUpdateVehicle(vehicleData);
  //
  // Navigator.pop(context, vehicleData); // Return to the home screen
  // }

  // void _deleteData() async {
  //   // Show a confirmation dialog before deleting
  //   bool confirmDelete = await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Delete Vehicle'),
  //         content: Text('Are you sure you want to delete this vehicle?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: Text('Cancel'),
  //           ),
  //           // TextButton(
  //           //   onPressed: () => Navigator.pop(context, true),
  //           //   child: Text('Delete', style: TextStyle(color: Colors.red)),
  //           // ),
  //         ],
  //       );
  //     },
  //   );

  // If the user confirms deletion
  //   if (confirmDelete == true) {
  //     await prefs?.remove('vehicleData'); // Replace with your key
  //
  //     // Show a confirmation message
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Vehicle deleted successfully!')));
  //
  //     // Navigate back to the previous screen
  //     Navigator.pop(context);
  //   }
  // }

  void _logout() async {
    // Show a confirmation dialog before deleting
    bool confirmLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Logout'),
              content: Text('Are you sure you want to Logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      () => NavigationService().navigateToUntil(
                        Screenroutes.login,
                      ),
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmLogout) {
      NavigationService().navigateToUntil(Screenroutes.login);

      // Use a short delay to ensure navigation completes before showing the message
      Future.delayed(Duration(milliseconds: 500), () {
        final context = NavigationService().navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User Logged out successfully!')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleData = widget.data;
    return Consumer<VehicleController>(
      builder: (context, vehicleController, child) {
        final vehicleTypeData = vehicleController.vehicleTypeData;
        final unitData = vehicleController.unitData;
        final customerData = vehicleController.customerData;

        return Scaffold(
          appBar: AppBar(title: Text('Edit Vehicle Details')),
          body:
              vehicleTypeData == null || unitData == null
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedCustomer,
                              items:
                                  (customerData ?? []).map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['Name'],
                                      child: Text(item['Name']),
                                      onTap: () {
                                        // Update the selected vehicle type ID
                                        setState(() {
                                          _selectedCustomerId = item['id'];
                                        });
                                      },
                                    );
                                  }).toList(),

                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCustomer = newValue;
                                  _customerNameController.text = newValue ?? '';
                                });
                              },
                            ),

                            SizedBox(height: 20),
                            // Type Dropdown
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
                                        // Update the selected vehicle type ID
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

                            // Plate Number TextField
                            TextField(
                              readOnly: true,

                              controller: _plateNumberController,
                              decoration: InputDecoration(
                                labelText: 'Plate Number',
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                  ), // Grey border when disabled
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                  ), // No highlight when focused
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                            SizedBox(height: 20),

                            // Capacity Row (TextField + Dropdown)
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
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Unit',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedCapacityUnit,
                                    items:
                                        (unitData ?? []).map((item) {
                                          return DropdownMenuItem<String>(
                                            value: item['Name'],
                                            child: Text(item['Name']),
                                            onTap: () {
                                              setState(() {
                                                _selectedCapacityUnitId =
                                                    item['id'];
                                              });
                                            },
                                          );
                                        }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedCapacityUnit = newValue;
                                        _capacityUnitController.text =
                                            newValue ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Note TextField
                            TextField(
                              controller: _noteController,
                              decoration: InputDecoration(
                                labelText: 'Note',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 20),

                            // Selected Images GridView
                            _selectedImages.isNotEmpty
                                ? GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    final file = _selectedImages[index];
                                    return FutureBuilder<bool>(
                                      future: file.exists(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        } else if (!snapshot.hasData ||
                                            !snapshot.data!) {
                                          // File does not exist, show a placeholder
                                          return Container(
                                            width: 150,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        } else {
                                          // File exists, display the image
                                          return Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                              ),
                                              GestureDetector(
                                                onTap:
                                                    () => _removeImage(index),
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
                                        }
                                      },
                                    );
                                  },
                                )
                                : Text('No images selected.'),
                            SizedBox(height: 10),

                            // Buttons for adding images
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: Icon(
                                    Icons.photo_library,
                                    color: Appcolors.textWhiteColor(context),
                                  ),
                                  label: Text(
                                    'Gallery',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.copyWith(
                                      color: Appcolors.textWhiteColor(context),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _captureImageFromCamera,
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Appcolors.textWhiteColor(context),
                                  ),
                                  label: Text(
                                    'Camera',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.copyWith(
                                      color: Appcolors.textWhiteColor(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 80,
                            ), // Extra space for the Save button
                          ],
                        ),
                      ),

                      // Save Button (Sticky at the bottom)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          // color: Colors.white,
                          padding: EdgeInsets.all(16.0),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Expanded(
                                  //   child: ElevatedButton(
                                  //     onPressed: _deleteData,
                                  //     style: ElevatedButton.styleFrom(
                                  //       padding: EdgeInsets.symmetric(
                                  //         horizontal: 50,
                                  //         vertical: 15,
                                  //       ),
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(10),
                                  //       ),
                                  //       minimumSize: Size(double.infinity, 10),
                                  //     ),
                                  //     child: Text('Delete', style: TextStyle(fontSize: 18)),
                                  //   ),
                                  // ),
                                  // SizedBox(width: 10),
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
                                        minimumSize: Size(double.infinity, 10),
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
                              // ElevatedButton(
                              //   onPressed: _logout,
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor: Colors.red, // Red color for logout
                              //     padding: EdgeInsets.symmetric(vertical: 15),
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //     ),
                              //     minimumSize: Size(double.infinity, 10),
                              //   ),
                              //   child: Text(
                              //     'Logout',
                              //     style: TextStyle(fontSize: 18, color: Colors.white),
                              //   ),
                              // ),
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
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        image.path,
      ).copy('${appDir.path}/$fileName');
      setState(() {
        _selectedImages.add(savedImage); // Add the File object
      });
    }
  }

  Future<void> _captureImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        image.path,
      ).copy('${appDir.path}/$fileName');
      setState(() {
        _selectedImages.add(savedImage); // Add the File object
      });
    }
  }
}
