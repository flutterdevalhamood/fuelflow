import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelRefillController with ChangeNotifier {
  List<Map<String, dynamic>>? unitData;
  List<Map<String, dynamic>>? productData;
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? driverData;
  List<Map<String, dynamic>>? refillUnitsData;
  List<Map<String, dynamic>>? vehicleTypeData;
  List<Map<String, dynamic>>? vehicleData;
  String? defaultProductName;
  String? defaultUnitName;
  int? defaultProductId;
  int? defaultCapacityUnitId;
  int? refillId;
  List<Map<String, dynamic>>? refillData;
  bool isLoading = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;

  TextEditingController? _unitController;
  TextEditingController? _productController;

  void setUnitController(TextEditingController unitController) {
    _unitController = unitController;
  }

  void setProductController(TextEditingController productController) {
    _productController = productController;
  }

  Future<void> getRefilldata({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();
    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final refillvehicle = await restApi.getRefilData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      print('API Response: ${refillvehicle}');

      if (refillvehicle is Map<String, dynamic>) {
        if (refillvehicle['IsSuccess'] == true) {
          // Extract the data from the response
          final data = refillvehicle['Data'] as List<dynamic>?;
          if (data != null) {
            // Convert the data to a List of Maps
            final newRefillData =
                data.map((v) => v as Map<String, dynamic>).toList();
            print('newRefillData: $newRefillData');
            if (loadMore) {
              refillData ??= [];
              refillData!.addAll(newRefillData); // Append to existing list
            } else {
              refillData = newRefillData; // Replace list on initial load
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          print('API call failed: ${refillvehicle['Message']}');
        }
      } else {
        print('Unexpected API response format');
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {}
    currentPage++;
    getRefilldata(loadMore: true);
  }

  Future<void> getVehicleDropDown() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final dropDownData = await restApi.getVehicleDropDownData(
        'Bearer $token',
      );
      if (dropDownData['IsSuccess'] == true) {
        vehicleTypeData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['vehicle_type'],
        );
        unitData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['unit'],
        );
        customerData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['customer'],
        );

        notifyListeners();
      } else {
        print('API call failed: ${dropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }

  Future<void> getFuelRefillDropdown() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final dropDownData = await restApi.getRefillDropDown('Bearer $token');
      if (dropDownData['IsSuccess'] == true) {
        unitData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['unit'],
        );
        productData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['product'],
        );
        customerData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['customer'],
        );
        refillUnitsData = List<Map<String, dynamic>>.from(
          dropDownData['Data']['refil_units'],
        );
        notifyListeners();
      } else {
        print('API call failed: ${dropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }

  Future<void> getDriverVehicleDropdown(int? customerId) async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final driverVehicleDropDownData = await restApi
          .getDriverVehicleOfCustomer(
            token: 'Bearer $token',
            customerId: customerId,
          );
      if (driverVehicleDropDownData['IsSuccess'] == true) {
        driverData = List<Map<String, dynamic>>.from(
          driverVehicleDropDownData['Data']['driver'],
        );
        print('driverdatacontroller $driverData');
        vehicleData = List<Map<String, dynamic>>.from(
          driverVehicleDropDownData['Data']['vehicle'],
        );
        notifyListeners();
      } else {
        print('API call failed: ${driverVehicleDropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }

  Future<bool> postRefillData({
    String? qty,
    int? customerId,
    int? unitId,
    int? productId,
    int? driverId,
    int? vehicleId,
    int? refillingUnitId,
    List<MultipartFile>? files,
  }) async {
    try {
      final postRefillData = await restApi.postRefilData(
        token: 'Bearer $token',
        quantity: qty,
        customerId: customerId,
        unitId: unitId,
        productId: productId,
        driverId: driverId,
        vehicleId: vehicleId,
        refillingUnitId: refillingUnitId,
        files: files,
      );

      if (postRefillData['IsSuccess'] == true) {
        refillId = postRefillData['Data'];
        notifyListeners();
        print('refillidd $refillId');
        return true;
      } else {
        print('API call failed: ${postRefillData['Message']}');
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<void> editRefillData(int? id, String? capacity, int? driverId) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.refillUpdate(
        token: 'Bearer $token',
        id: id,
        qty: capacity,
        driverId: driverId,
      );
      getRefilldata();
      notifyListeners();
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<void> deleteImagesById(int? id) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteRefillingUnitImagesById(
        token: 'Bearer $token',
        id: id,
      );
      await getRefilldata();
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<bool> uploadRefillImages(
    List<MultipartFile>? files,
    String? id,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final response = await restApi.uploadRefillImages(
        token: 'Bearer $token',
        files: files,
        id: id,
      );

      print('API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          print('Images uploaded successfully');
          return true;
        } else {
          print('Image upload failed: ${response['Message']}');
          return false;
        }
      } else {
        print('Unexpected API response format');
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> deleteRefillData(int? id, String? descriptionText) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.refillDelete(
        token: 'Bearer $token',
        id: id,
        deleteDescription: descriptionText,
      );
      await getRefilldata();
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<void> getUnitProductDropdown(int? refillId) async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final unitProductDropDownData = await restApi.getDefaultsOfRefilingUnit(
        token: 'Bearer $token',
        refillingUnitId: refillId,
      );
      if (unitProductDropDownData['IsSuccess'] == true) {
        defaultProductName =
            unitProductDropDownData['Data']?['defaults']?['default_product']?['Name'];
        defaultUnitName =
            unitProductDropDownData['Data']?['defaults']?['capacity_unit']?['Name'];
        defaultProductId =
            unitProductDropDownData['Data']?['defaults']?['default_product']?['id'];
        defaultCapacityUnitId =
            unitProductDropDownData['Data']?['defaults']?['capacity_unit']?['id'];
        if (_unitController != null) {
          _unitController?.text = defaultUnitName ?? '';
        }
        if (_productController != null) {
          _productController?.text = defaultProductName ?? '';
        }
        print('unitcontrollertext ${_unitController?.text}');

        notifyListeners();
      } else {
        print('API call failed: ${unitProductDropDownData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    }
  }
}
