import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleProvider with ChangeNotifier {
  List<Map<String, dynamic>> _vehicles = [];
  bool _resetDone = false;

  bool get resetDone => _resetDone;

  String? _selectedType;
  String? _selectedcapacity;
  List<File> _selectedImages = [];
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? get selectedType => _selectedType;
  String? get selectedCapacity => _selectedcapacity;
  List<Map<String, dynamic>> get vehicles => _vehicles;
  List<File> get selectedImages => _selectedImages;
  TextEditingController get plateNumberController => _plateNumberController;
  TextEditingController get capacityController => _capacityController;
  TextEditingController get noteController => _noteController;

  VehicleProvider() {
    loadVehicles();
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existingVehicles = prefs.getStringList('vehicles') ?? [];
    Map<String, dynamic> newVehicle = {
      'type': _selectedType ?? '',
      'plateNumber': _plateNumberController.text,
      'capacity': _capacityController.text,
      'capacityUnit': _selectedcapacity ?? '',
      'note': _noteController.text,
      'images':
          _selectedImages.map((image) => image.path.split('/').last).toList(),
    };
    existingVehicles.add(jsonEncode(newVehicle));
    await prefs.setStringList('vehicles', existingVehicles);
    await loadVehicles();
  }

  void setSelectedType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSelectedCapacity(String? capacity) {
    _selectedcapacity = capacity;
    notifyListeners();
  }

  void addImage(File image) {
    _selectedImages.add(image);
    notifyListeners();
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  void clearControllers() {
    _plateNumberController.clear();
    _capacityController.clear();
    _noteController.clear();
    _selectedImages.clear();
    _selectedType = null;
    _selectedcapacity = null;
    _resetDone = true;
    notifyListeners();
  }

  void resetFlag() {
    _resetDone = false;
  }

  Future<void> loadVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedVehicles = prefs.getStringList('vehicles') ?? [];

    _vehicles =
        savedVehicles.map((vehicle) {
          return jsonDecode(vehicle) as Map<String, dynamic>;
        }).toList();

    notifyListeners();
  }

  Future<void> addOrUpdateVehicle(Map<String, dynamic> vehicleData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedVehicles = prefs.getStringList('vehicles') ?? [];

    bool isUpdated = false;
    List<String> updatedVehicles = [];

    for (String vehicleJson in savedVehicles) {
      Map<String, dynamic> existingVehicle = jsonDecode(vehicleJson);

      if (existingVehicle['plateNumber'] == vehicleData['plateNumber']) {
        updatedVehicles.add(jsonEncode(vehicleData));
        isUpdated = true;
      } else {
        updatedVehicles.add(jsonEncode(existingVehicle));
      }
    }

    if (!isUpdated) {
      // Add new vehicle if it was not updated
      updatedVehicles.add(jsonEncode(vehicleData));
    }

    await prefs.setStringList('vehicles', updatedVehicles);
    loadVehicles(); // Refresh the list and notify UI
  }

  Future<void> deleteVehicle(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedVehicles = prefs.getStringList('vehicles') ?? [];

    if (index >= 0 && index < savedVehicles.length) {
      savedVehicles.removeAt(index);
      await prefs.setStringList('vehicles', savedVehicles);
      loadVehicles();
      notifyListeners();
    }
  }
}
