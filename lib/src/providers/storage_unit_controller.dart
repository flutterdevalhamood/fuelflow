import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class StorageUnitController with ChangeNotifier {
  List<Map<String, dynamic>>? unitData;
  List<Map<String, dynamic>>? driverData;
  List<Map<String, dynamic>>? productData;
  List<Map<String, dynamic>>? vehicleData;
  int? refillUnitId;
  List<Map<String, dynamic>>? storageUnitData;
  bool isLoading = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? refillUnitsData;

  Future<void> getStorageUnitData({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final storageUnit = await restApi.getStorageUnitData(
        currentPage,
        totalPages,
        'Bearer $token',
      );

      if (storageUnit is Map<String, dynamic>) {
        if (storageUnit['IsSuccess'] == true) {
          final data = storageUnit['Data'] as List<dynamic>?;
          if (data != null) {
            final newStorageUnitData =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              storageUnitData ??= [];
              storageUnitData!.addAll(
                newStorageUnitData,
              ); // Append to existing list
            } else {
              storageUnitData =
                  newStorageUnitData; // Replace list on initial load
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          print('API call failed: ${storageUnit['Message']}');
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
    getStorageUnitData(loadMore: true);
  }

  Future<void> getRefillUnitDropDown() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final RefillUnitdropDownData = await restApi.refillingUnitBaseList(
        token: 'Bearer $token',
      );
      if (RefillUnitdropDownData['IsSuccess'] == true) {
        vehicleData = List<Map<String, dynamic>>.from(
          RefillUnitdropDownData['Data']['vehicles'],
        );
        driverData = List<Map<String, dynamic>>.from(
          RefillUnitdropDownData['Data']['driver'],
        );
        productData = List<Map<String, dynamic>>.from(
          RefillUnitdropDownData['Data']['products'],
        );
        unitData = List<Map<String, dynamic>>.from(
          RefillUnitdropDownData['Data']['capacity_units'],
        );
        notifyListeners();
      } else {
        print('API call failed: ${RefillUnitdropDownData['Message']}');
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

  Future<bool> postStorageUnitData({
    int? id,
    int? driverId,
    int? vehicleId,
    int? productId,
    int? qty,
    int? unitId,
    String? description,
    List<MultipartFile>? files,
  }) async {
    try {
      final postStorageUnitData = await restApi.postStorageUnitData(
        token: 'Bearer $token',
        id: id,
        driverId: driverId,
        vehicleId: vehicleId,
        productId: productId,
        qty: qty,
        unitId: unitId,
        description: description,
        files: files,
      );

      if (postStorageUnitData['IsSuccess'] == true) {
        refillUnitId = postStorageUnitData['Data'];
        notifyListeners();

        getStorageUnitData();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }
}
