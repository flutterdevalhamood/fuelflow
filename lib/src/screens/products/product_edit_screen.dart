import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/Product_controller.dart';
import 'package:sample/src/util/snack.dart';

class ProductEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProductEditScreen({super.key, required this.data});

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late ProductController _productListController;
  File? selectedFile;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productListController = Provider.of<ProductController>(
        context,
        listen: false,
      );
      _productListController.getProductData();
    });
    super.initState();
    _productNameController = TextEditingController(text: widget.data['Name']);
  }

  @override
  void dispose() {
    // Dispose controllers
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final id = widget.data['id'];
    final productName = _productNameController.text.trim();

    if (id != null) {
      bool isSuccess = await _productListController.updateProduct(
        id,
        productName,
      );
      if (isSuccess) {
        showSuccessSnack('Product updated successfully');
        Navigator.pop(context, true);
      } else {
        showErrorSnack('Error updating data');
      }
    } else {
      showErrorSnack("cannot find Driver id");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        actions: [
          IconButton(
            onPressed: () {
              saveEditedData();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: _buildTextField(
              controller: _productNameController,
              label: 'Product Name',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
