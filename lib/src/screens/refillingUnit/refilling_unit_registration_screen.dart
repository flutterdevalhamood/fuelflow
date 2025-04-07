import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_driver_card.dart';
import 'package:sample/src/screens/fuelRefill/fuel_refill_vehicle_card.dart';
import 'package:sample/src/util/image_compress.dart';
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
  List<XFile>? _vehicleImageFiles;
  List<XFile>? _driverImageFiles;
  bool _showVehicleImages = false;
  bool _showDriverImages = false;
  bool _isLoading = false;

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
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isLoading = true);
      if ((_vehicleImageFiles == null || _vehicleImageFiles!.isEmpty) &&
          (_driverImageFiles == null || _driverImageFiles!.isEmpty)) {
        setState(() => _isLoading = false);
        showErrorSnack("Please select at least one image");
        return;
      }

      // Process images in parallel
      final vehicleImages = _vehicleImageFiles ?? [];
      final driverImages = _driverImageFiles ?? [];

      final List<MultipartFile> allImages = [];
      for (var file in [...vehicleImages, ...driverImages]) {
        final compressedFile = await compressImage(file.path);
        allImages.add(await MultipartFile.fromFile(compressedFile.path));
      }

      final apiCall = await _refillingUnitController.postRefillUnitData(
        type: _selectedType,
        serialNo: _serialNumberController.text.trim(),
        vehicleId: _selectedVehicleId,
        driverId: _selectedDriverId,
        productId: _selectedProductId,
        capacity: _capacityController.text.trim(),
        capacityUnitId: _selectedCapacityUnitId,
        files: allImages,
      );
      final isSuccess = await apiCall;
      setState(() => _isLoading = false);
      if (isSuccess) {
        showSuccessSnack("Refill Unit entry Successfull!");
        Navigator.pop(context, true);
        // NavigationService().pushAndRemoveUntilNavigation(
        //   Screenroutes.refillingUnitListScreen,
        //   removeUntilPageName: Screenroutes.refillingUnitListScreen,
        // );
      } else {
        showErrorSnack("Error uploading Refill Unit data");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorSnack("An error occurred: ${e.toString()}");
      debugPrint("Error in _postRefillData: $e");
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(bool isVehicle) async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80, // Reduce image quality for faster processing
        maxWidth: 1920, // Limit image size
      );

      // final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          if (isVehicle) {
            _vehicleImageFiles = [...?_vehicleImageFiles, ...pickedFiles];
          } else {
            _driverImageFiles = [...?_driverImageFiles, ...pickedFiles];
          }
          // _imageFiles = [...?_imageFiles, ...pickedFiles];
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
      showErrorSnack("Failed to pick images");
    }
  }

  Future<void> _takePicture(bool isVehicle) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
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
    } catch (e) {
      debugPrint("Error taking picture: $e");
      showErrorSnack("Failed to take picture");
    }
  }

  // Future<void> _takePicture() async {
  //   final XFile? pickedFile = await _picker.pickImage(
  //     source: ImageSource.camera,
  //   );
  //   if (pickedFile != null) {
  //     setState(() {
  //       _imageFiles = [...?_imageFiles, pickedFile];
  //     });
  //   }
  // }

  // Future<void> _uploadImages() async {
  //   final _refillId = _refillingUnitController.refillUnitId;
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
  //   if (_refillId != null) {
  //     bool isSuccess = await _refillingUnitController.uploadRefillUnitImages(
  //       multipartFiles,
  //       _refillId.toString(),
  //     );
  //     if (isSuccess) {
  //       showSuccessSnack('Image uploaded successfully');
  //       NavigationService().pushAndRemoveUntilNavigation(
  //         Screenroutes.refillingUnitListScreen,
  //         removeUntilPageName: Screenroutes.refillingUnitListScreen,
  //       );
  //     } else {
  //       showErrorSnack('Error uploading image');
  //     }
  //   } else {
  //     print('Refill Unit ID is null');
  //   }
  // }

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
                              // if (!_isRegistrationComplete) ...[
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
                                  return null;
                                },
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
                              // DropdownSearch<Map<String, dynamic>>(
                              //   popupProps: PopupProps.menu(
                              //     showSearchBox: true,
                              //     fit: FlexFit.tight,
                              //     searchFieldProps: TextFieldProps(
                              //       decoration: InputDecoration(
                              //         hintText: 'Search Vehicle...',
                              //       ),
                              //     ),
                              //   ),
                              //   items:
                              //       (filter, infiniteScrollProps) =>
                              //           vehicleData,
                              //   itemAsString:
                              //       (item) => item['plate_no'] ?? '',
                              //   compareFn: (
                              //     Map<String, dynamic> item1,
                              //     Map<String, dynamic> item2,
                              //   ) {
                              //     return item1['id'] ==
                              //         item2['id']; // Compare items by their ID
                              //   },
                              //   onChanged: (
                              //     Map<String, dynamic>? newValue,
                              //   ) async {
                              //     if (newValue != null) {
                              //       setState(() {
                              //         _selectedVehicleId = newValue['id'];
                              //         _vehicleController.text =
                              //             newValue['plate_no'];
                              //       });
                              //     }
                              //   },
                              //   selectedItem:
                              //       _selectedVehicleId != null
                              //           ? vehicleData.firstWhere(
                              //             (vehicle) =>
                              //                 vehicle['id'] ==
                              //                 _selectedVehicleId,
                              //           )
                              //           : null,
                              //   validator: (value) {
                              //     if (value == null) {
                              //       return 'Please select a Vehicle';
                              //     }
                              //     return null;
                              //   },
                              //   decoratorProps: DropDownDecoratorProps(
                              //     decoration: InputDecoration(
                              //       labelText: 'Vehicle',
                              //       border: OutlineInputBorder(),
                              //     ),
                              //   ),
                              // ),
                              // SizedBox(height: 20),
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

                              // DropdownSearch<Map<String, dynamic>>(
                              //   popupProps: PopupProps.menu(
                              //     showSearchBox: true,
                              //     fit: FlexFit.tight,
                              //     searchFieldProps: TextFieldProps(
                              //       decoration: InputDecoration(
                              //         hintText: 'Search Driver...',
                              //       ),
                              //     ),
                              //   ),
                              //   items:
                              //       (filter, infiniteScrollProps) =>
                              //           driverData,
                              //   itemAsString: (item) => item['Name'] ?? '',
                              //   compareFn: (
                              //     Map<String, dynamic> item1,
                              //     Map<String, dynamic> item2,
                              //   ) {
                              //     return item1['id'] ==
                              //         item2['id']; // Compare items by their ID
                              //   },
                              //   onChanged: (
                              //     Map<String, dynamic>? newValue,
                              //   ) async {
                              //     if (newValue != null) {
                              //       setState(() {
                              //         _selectedDriverId = newValue['id'];
                              //         _driverController.text =
                              //             newValue['Name'];
                              //       });
                              //     }
                              //   },
                              //   selectedItem:
                              //       _selectedDriverId != null
                              //           ? driverData.firstWhere(
                              //             (driver) =>
                              //                 driver['id'] ==
                              //                 _selectedDriverId,
                              //           )
                              //           : null,
                              //   validator: (value) {
                              //     if (value == null) {
                              //       return 'Please select a Driver';
                              //     }
                              //     return null;
                              //   },
                              //   decoratorProps: DropDownDecoratorProps(
                              //     decoration: InputDecoration(
                              //       labelText: 'Driver',
                              //       border: OutlineInputBorder(),
                              //     ),
                              //   ),
                              // ),
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
                                    child: TextFormField(
                                      controller: _capacityController,
                                      decoration: InputDecoration(
                                        labelText: 'Capacity',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter Capacity';
                                        }
                                        return null;
                                      },
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
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Enter Unit';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 100),
                              // ],
                              // if (_isRegistrationComplete) ...[
                              // Text(
                              //   'Pictures',
                              //   style: Theme.of(context).textTheme.bodyLarge!
                              //       .copyWith(fontWeight: FontWeight.bold),
                              // ),
                              // SizedBox(height: 10),
                              //
                              // _imageFiles != null && _imageFiles!.isNotEmpty
                              //     ? GridView.builder(
                              //       shrinkWrap: true,
                              //       physics: NeverScrollableScrollPhysics(),
                              //       gridDelegate:
                              //           SliverGridDelegateWithFixedCrossAxisCount(
                              //             crossAxisCount: 3,
                              //             crossAxisSpacing: 8,
                              //             mainAxisSpacing: 8,
                              //           ),
                              //       itemCount: _imageFiles!.length,
                              //       itemBuilder: (context, index) {
                              //         return Stack(
                              //           alignment: Alignment.topRight,
                              //           children: [
                              //             GestureDetector(
                              //               onTap: () {
                              //                 showFullScreenImage(
                              //                   context,
                              //                   _imageFiles!,
                              //                   index,
                              //                 );
                              //               },
                              //               child: Image.file(
                              //                 File(_imageFiles![index].path),
                              //                 fit: BoxFit.cover,
                              //               ),
                              //             ),
                              //             GestureDetector(
                              //               onTap: () {
                              //                 setState(() {
                              //                   _imageFiles!.removeAt(index);
                              //                 });
                              //               },
                              //               child: Container(
                              //                 margin: EdgeInsets.all(4),
                              //                 decoration: BoxDecoration(
                              //                   color: Colors.black.withOpacity(
                              //                     0.5,
                              //                   ),
                              //                   shape: BoxShape.circle,
                              //                 ),
                              //                 child: Icon(
                              //                   Icons.close,
                              //                   color: Colors.white,
                              //                   size: 20,
                              //                 ),
                              //               ),
                              //             ),
                              //           ],
                              //         );
                              //       },
                              //     )
                              //     : Text('No images selected.'),
                              // SizedBox(height: 10),
                              // Row(
                              //   mainAxisAlignment:
                              //       MainAxisAlignment.spaceEvenly,
                              //   children: [
                              //     ElevatedButton.icon(
                              //       onPressed: () => _pickImages(isVehicle),
                              //       icon: Icon(
                              //         Icons.photo_library,
                              //         color: Appcolors.textWhiteColor(context),
                              //       ),
                              //       label: Text(
                              //         'Gallery',
                              //         style: Theme.of(
                              //           context,
                              //         ).textTheme.bodyMedium!.copyWith(
                              //           color: Appcolors.textWhiteColor(
                              //             context,
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //     ElevatedButton.icon(
                              //       onPressed: () => _takePicture(isVehicle),
                              //       icon: Icon(
                              //         Icons.camera_alt,
                              //         color: Appcolors.textWhiteColor(context),
                              //       ),
                              //       label: Center(
                              //         child: Text(
                              //           'Camera',
                              //           style: Theme.of(
                              //             context,
                              //           ).textTheme.bodyMedium!.copyWith(
                              //             color: Appcolors.textWhiteColor(
                              //               context,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              SizedBox(height: 80),
                              // ],
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
                                _isLoading
                                    ? null
                                    : () async {
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
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Appcolors.textWhiteColor(context),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'Save',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.copyWith(
                                        color: Appcolors.textWhiteColor(
                                          context,
                                        ),
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
