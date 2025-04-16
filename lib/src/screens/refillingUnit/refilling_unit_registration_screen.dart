import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
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
  List<XFile>? _vehicleImageFiles;
  List<XFile>? _driverImageFiles;
  bool _showVehicleImages = false;
  bool _showDriverImages = false;
  bool _isLoading = false;
  int? _selectedType = 0;

  final ImagePicker _imagePicker = ImagePicker();
  // final ImageCompressor _imageCompressor = ImageCompressor();

  List<CameraDescription>? cameras;
  CameraController? _controller;

  @override
  void initState() {
    _initializeCamera();
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

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0], // Use first camera (usually rear)
        ResolutionPreset.medium,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCameraScreen(bool isVehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CameraScreen(
              isVehicle: isVehicle,
              onImageCaptured: (imageFile) async {
                final compressedFile = await compressImage(imageFile.path);

                if (mounted) {
                  setState(() {
                    if (isVehicle) {
                      _vehicleImageFiles = [
                        ...?_vehicleImageFiles,
                        XFile(compressedFile.path),
                      ];
                    } else {
                      _driverImageFiles = [
                        ...?_driverImageFiles,
                        XFile(compressedFile.path),
                      ];
                    }
                  });
                }
              },
            ),
      ),
    );
  }

  // Future<void> _takePictureWithCameraPackage(bool isVehicle) async {
  //   if (_controller == null || !_controller!.value.isInitialized) {
  //     return;
  //   }
  //
  //   try {
  //     final image = await _controller!.takePicture();
  //     final compressedFile = await compressImage(image.path);
  //
  //     if (mounted) {
  //       setState(() {
  //         if (isVehicle) {
  //           _vehicleImageFiles = [
  //             ...?_vehicleImageFiles,
  //             XFile(compressedFile.path),
  //           ];
  //         } else {
  //           _driverImageFiles = [
  //             ...?_driverImageFiles,
  //             XFile(compressedFile.path),
  //           ];
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error taking picture: $e");
  //     if (mounted) {
  //       showErrorSnack("Failed to take picture: ${e.toString()}");
  //     }
  //   }
  // }

  Future<void> _postRefillData() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (mounted) setState(() => _isLoading = true);
      if ((_vehicleImageFiles == null || _vehicleImageFiles!.isEmpty) &&
          (_driverImageFiles == null || _driverImageFiles!.isEmpty)) {
        setState(() => _isLoading = false);
        showErrorSnack("Please select at least one image");
        return;
      }

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
        showSuccessSnack("Refill Unit entry Successful!");
        Navigator.pop(context, true);
      } else {
        showErrorSnack("Error uploading Refill Unit data");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showErrorSnack("An error occurred: ${e.toString()}");
      debugPrint("Error in _postRefillData: $e");
    }
  }

  Future<void> _pickImages(bool isVehicle) async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
      );

      if (pickedFiles != null && mounted) {
        setState(() {
          if (isVehicle) {
            _vehicleImageFiles = [...?_vehicleImageFiles, ...pickedFiles];
          } else {
            _driverImageFiles = [...?_driverImageFiles, ...pickedFiles];
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
      if (mounted) showErrorSnack("Failed to pick images");
    }
  }

  // Future<void> _takePicture(bool isVehicle) async {
  //   if (!mounted) return;
  //
  //   try {
  //     final pickedFile = await _imagePicker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 70,
  //       preferredCameraDevice: CameraDevice.rear,
  //     );
  //
  //     if (pickedFile == null || !mounted) return;
  //
  //     // Compress the image immediately after capture
  //     final compressedFile = await compressImage(pickedFile.path);
  //
  //     setState(() {
  //       if (isVehicle) {
  //         _vehicleImageFiles = [
  //           ...?_vehicleImageFiles,
  //           XFile(compressedFile.path),
  //         ];
  //       } else {
  //         _driverImageFiles = [
  //           ...?_driverImageFiles,
  //           XFile(compressedFile.path),
  //         ];
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint("Error taking picture: $e");
  //     if (mounted) {
  //       showErrorSnack("Failed to take picture: ${e.toString()}");
  //     }
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
        if (images != null && images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return FutureBuilder<File?>(
                future: File(images[index].path).exists().then(
                  (exists) => exists ? File(images[index].path) : null,
                ),
                builder: (context, snapshot) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      if (snapshot.hasData && snapshot.data != null)
                        GestureDetector(
                          onTap: () {
                            showFullScreenImage(context, images, index);
                          },
                          child: Image.file(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                child: child,
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              if (isVehicle) {
                                _vehicleImageFiles!.removeAt(index);
                              } else {
                                _driverImageFiles!.removeAt(index);
                              }
                            });
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
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
              );
            },
          )
        else
          Text('No $title images selected.'),
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
              onPressed: () => _openCameraScreen(isVehicle),
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

        return Scaffold(
          appBar: AppBar(
            title: Text('Refilling Unit Entry'),
            centerTitle: true,
          ),
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
                                      if (mounted) {
                                        setState(() {
                                          _selectedType = value;
                                        });
                                      }
                                    },
                                  ),
                                  Text('Vehicle'),
                                  Radio(
                                    value: 1,
                                    groupValue: _selectedType,
                                    onChanged: (int? value) {
                                      if (mounted) {
                                        setState(() {
                                          _selectedType = value;
                                        });
                                      }
                                    },
                                  ),
                                  Text('Tank'),
                                ],
                              ),
                              TextFormField(
                                controller: _serialNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Refilling Unit Serial Number*',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter Serial Number';
                                  }
                                  return null;
                                },
                              ),
                              _selectedType == 1
                                  ? SizedBox.shrink()
                                  : SizedBox(height: 20),
                              _selectedType == 0
                                  ? TextFormField(
                                    controller: _vehicleController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle Number*',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.arrow_forward_ios),
                                    ),
                                    onTap: () async {
                                      final selectedVehicle =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      FuelRefillVehicleCard(
                                                        vehicles:
                                                            vehicleData ?? [],
                                                      ),
                                            ),
                                          );

                                      if (selectedVehicle != null && mounted) {
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
                                  )
                                  : SizedBox.shrink(),
                              if (_showVehicleImages)
                                _buildImageSection(
                                  'Vehicle',
                                  _vehicleImageFiles,
                                  true,
                                ),
                              SizedBox(height: 20),
                              _selectedType == 0
                                  ? TextFormField(
                                    controller: _driverController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Driver Name',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.arrow_forward_ios),
                                    ),
                                    onTap: () async {
                                      final selectedDriver =
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      FuelRefillDriverCard(
                                                        drivers:
                                                            driverData ?? [],
                                                      ),
                                            ),
                                          );

                                      if (selectedDriver != null && mounted) {
                                        setState(() {
                                          _selectedDriverId =
                                              selectedDriver['id'];
                                          _driverController.text =
                                              selectedDriver['Name'];
                                          _showDriverImages = true;
                                        });
                                      }
                                    },
                                  )
                                  : SizedBox.shrink(),
                              if (_showDriverImages)
                                _buildImageSection(
                                  'Driver',
                                  _driverImageFiles,
                                  false,
                                ),
                              _selectedType == 0
                                  ? SizedBox(height: 20)
                                  : SizedBox.shrink(),
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
                                  return item1['id'] == item2['id'];
                                },
                                onChanged: (
                                  Map<String, dynamic>? newValue,
                                ) async {
                                  if (newValue != null && mounted) {
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
                                    labelText: 'Product Name*',
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
                                        labelText: 'Capacity*',
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
                                        labelText: 'Unit*',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: _selectedCapacityUnitId,
                                      items:
                                          (unitData ?? []).map((item) {
                                            return DropdownMenuItem<int>(
                                              value: item['id'],
                                              child: Text(item['Name']),
                                              onTap: () {
                                                if (mounted) {
                                                  setState(() {
                                                    _selectedCapacityUnitId =
                                                        item['id'];
                                                  });
                                                }
                                              },
                                            );
                                          }).toList(),
                                      onChanged: (int? newValue) {
                                        if (mounted) {
                                          setState(() {
                                            _selectedCapacityUnitId = newValue;
                                          });
                                        }
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
                                      await _postRefillData();
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

class CameraScreen extends StatefulWidget {
  final bool isVehicle;
  final Function(XFile) onImageCaptured;

  const CameraScreen({
    required this.isVehicle,
    required this.onImageCaptured,
    Key? key,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No cameras available')));
          Navigator.pop(context);
        }
        return;
      }

      _controller = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _isTakingPicture || _controller == null) return;

    setState(() => _isTakingPicture = true);

    try {
      final image = await _controller!.takePicture();
      widget.onImageCaptured(XFile(image.path));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take picture: $e')));
      }
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraReady && _controller != null)
            CameraPreview(_controller!),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isTakingPicture ? Colors.grey : Colors.white,
                onPressed: _takePicture,
                child: Icon(
                  _isTakingPicture ? Icons.timer : Icons.camera_alt,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
