import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/storage_unit_controller.dart';
import 'package:sample/src/util/snack.dart';
import 'package:sample/src/widgets/custom_storageunit_button.dart';

class StorageUnitRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? storageUnitData;

  const StorageUnitRegistrationScreen({Key? key, this.storageUnitData})
    : super(key: key);

  @override
  State<StorageUnitRegistrationScreen> createState() =>
      _StorageUnitRegistrationScreenState();
}

class _StorageUnitRegistrationScreenState
    extends State<StorageUnitRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();

  int? _selectedDriverId;
  int? _selectedVehicleId;
  int? _selectedProductId;
  int? _selectedUnitId;
  int? _selectedRefillUnitId;
  int? _selectedCustomerId;

  bool _isLoading = false;
  bool _isEditMode = false;

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<StorageUnitController>(
        context,
        listen: false,
      );

      // Load dropdown data
      controller.getRefillUnitDropDown();
      controller.getFuelRefillDropdown();

      // Check if we're in edit mode
      if (widget.storageUnitData != null) {
        _isEditMode = true;
        _populateFormFields();
      }
    });
  }

  void _populateFormFields() {
    final data = widget.storageUnitData!;

    setState(() {
      _selectedDriverId = data['driver_id'];
      _selectedVehicleId = data['vehicle_id'];
      _selectedProductId = data['product_id'];
      _selectedUnitId = data['unit_id'];
      _selectedRefillUnitId = data['refill_unit_id'];
      _selectedCustomerId = data['customer_id'];
      _capacityController.text = data['capacity']?.toString() ?? '';
      _descriptionController.text = data['description'] ?? '';
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDriverId == null) {
        showErrorSnack('Please select a driver');
        return;
      }

      if (_selectedVehicleId == null) {
        showErrorSnack('Please select a vehicle');
        return;
      }

      if (_selectedProductId == null) {
        showErrorSnack('Please select a product');
        return;
      }

      if (_selectedUnitId == null) {
        showErrorSnack('Please select a unit');
        return;
      }

      if (_selectedRefillUnitId == null) {
        showErrorSnack('Please select a refilling unit');
        return;
      }

      try {
        setState(() {
          _isLoading = true;
        });

        final controller = Provider.of<StorageUnitController>(
          context,
          listen: false,
        );

        // Convert images to MultipartFile
        List<MultipartFile> files = [];

        if (_selectedImages.isNotEmpty) {
          for (var image in _selectedImages) {
            files.add(
              await MultipartFile.fromFile(
                image.path,
                filename: image.path.split('/').last,
              ),
            );
          }
        }

        final isSuccess = await controller.postStorageUnitData(
          id: _selectedRefillUnitId,
          driverId: _selectedDriverId,
          vehicleId: _selectedVehicleId,
          productId: _selectedProductId,
          qty: int.tryParse(_capacityController.text) ?? 0,
          unitId: _selectedUnitId,
          description: _descriptionController.text,
          files: files,
        );

        setState(() => _isLoading = false);

        if (!isSuccess) {
          showSuccessSnack(
            _isEditMode
                ? 'Storage unit updated successfully'
                : 'Storage unit registered successfully',
          );
          Navigator.pop(context, true);
        } else {
          showErrorSnack('Failed to save storage unit');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnack('An error occurred: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageUnitController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditMode ? 'Edit Storage Unit' : 'Register Storage Unit',
            ),
            elevation: 0,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Refilling Information'),
                            const SizedBox(height: 16),

                            // Refilling Unit Dropdown
                            _buildDropdownField(
                              label: 'Refilling Unit',
                              hint: 'Select Refilling Unit',
                              value: _selectedRefillUnitId,
                              items:
                                  controller.refillUnitsData?.map((unit) {
                                    return DropdownMenuItem<int>(
                                      value: unit['id'],
                                      child: Text(
                                        unit['serial_no'] ?? 'Unknown',
                                      ),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRefillUnitId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildSectionHeader('Vehicle Information'),
                            const SizedBox(height: 16),

                            // Driver Dropdown
                            _buildDropdownField(
                              label: 'Driver',
                              hint: 'Select Driver',
                              value: _selectedDriverId,
                              items:
                                  controller.driverData?.map((driver) {
                                    return DropdownMenuItem<int>(
                                      value: driver['id'],
                                      child: Text(driver['Name'] ?? 'Unknown'),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDriverId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Vehicle Dropdown
                            _buildDropdownField(
                              label: 'Vehicle',
                              hint: 'Select Vehicle',
                              value: _selectedVehicleId,
                              items:
                                  controller.vehicleData?.map((vehicle) {
                                    return DropdownMenuItem<int>(
                                      value: vehicle['id'],
                                      child: Text(
                                        vehicle['plate_no'] ?? 'Unknown',
                                      ),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            _buildSectionHeader('Storage Details'),
                            const SizedBox(height: 16),

                            // Product Dropdown
                            _buildDropdownField(
                              label: 'Product',
                              hint: 'Select Product',
                              value: _selectedProductId,
                              items:
                                  controller.productData?.map((product) {
                                    return DropdownMenuItem<int>(
                                      value: product['id'],
                                      child: Text(product['Name'] ?? 'Unknown'),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedProductId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Capacity with Unit Dropdown
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _capacityController,
                                    label: 'Capacity',
                                    hint: 'Enter capacity',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter capacity';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildDropdownField(
                                    label: 'Unit',
                                    hint: 'Unit',
                                    value: _selectedUnitId,
                                    items:
                                        controller.unitData?.map((unit) {
                                          return DropdownMenuItem<int>(
                                            value: unit['id'],
                                            child: Text(
                                              unit['Name'] ?? 'Unknown',
                                            ),
                                          );
                                        }).toList() ??
                                        [],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUnitId = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Description',
                              hint: 'Enter description',
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            _buildSectionHeader('Upload Images'),
                            const SizedBox(height: 16),

                            _buildImageSection(),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: CustomStorageUnitButton(
                                onPressed: _submitForm,
                                text: _isEditMode ? 'Update' : 'Register',
                                isLoading: _isLoading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<int>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              errorStyle: const TextStyle(height: 0.8),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
            isExpanded: true,
            dropdownColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            errorStyle: const TextStyle(height: 0.8),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected images
        if (_selectedImages.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // Add image button
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload images',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
