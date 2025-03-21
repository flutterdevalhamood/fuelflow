import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class RefillingUnitController with ChangeNotifier {
  List<Map<String, dynamic>>? unitData;
  List<Map<String, dynamic>>? driverData;
  List<Map<String, dynamic>>? productData;
  List<Map<String, dynamic>>? vehicleData;
  int? refillUnitId;
  List<Map<String, dynamic>>? refillUnitData;
  bool isLoading = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;

  Future<void> getRefillUnitData({bool loadMore = false}) async {
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
      final refillUnit = await restApi.getRefilingUnitData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      print('API Response: ${refillUnit}');

      if (refillUnit is Map<String, dynamic>) {
        if (refillUnit['IsSuccess'] == true) {
          // Extract the data from the response
          final data = refillUnit['Data'] as List<dynamic>?;
          if (data != null) {
            // Convert the data to a List of Maps
            final newRefillUnitData =
                data.map((v) => v as Map<String, dynamic>).toList();
            print('newRefillUnitData: $newRefillUnitData');
            if (loadMore) {
              refillUnitData ??= [];
              refillUnitData!.addAll(
                newRefillUnitData,
              ); // Append to existing list
            } else {
              refillUnitData =
                  newRefillUnitData; // Replace list on initial load
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          print('API call failed: ${refillUnit['Message']}');
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
    getRefillUnitData(loadMore: true);
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

  Future<bool> postRefillUnitData({
    int? type,
    String? serialNo,
    int? vehicleId,
    int? driverId,
    String? capacity,
    int? capacityUnitId,
    int? productId,

    int? refillingUnitId,
  }) async {
    try {
      final postRefillUnitData = await restApi.postRefillingUnit(
        token: 'Bearer $token',
        type: type,
        serialNumber: serialNo,
        vehicleId: vehicleId,
        driverId: driverId,
        capacity: capacity,
        capacityUnitId: capacityUnitId,
        defaultProductId: productId,
      );

      if (postRefillUnitData['IsSuccess'] == true) {
        refillUnitId = postRefillUnitData['Data'];
        notifyListeners();
        print('refillUnitId $refillUnitId');
        return true;
      } else {
        print('API call failed: ${postRefillUnitData['Message']}');
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> uploadRefillUnitImages(
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

  Future<void> deleteRefillUnitData(int? id, String? descriptionText) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteRefillingUnit(
        token: 'Bearer $token',
        id: id,
        deleteDescription: descriptionText,
      );
      await getRefillUnitData();
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<void> editRefillUnitData(
    int? type,
    String? serialNumber,
    int? vehicleId,
    int? driverId,
    String? capacity,
    int? capacityUnitId,
    int? defaultProductId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.refillingUnitUpdate(
        token: 'Bearer $token',
        type: type,
        serialNumber: serialNumber,
        vehicleId: vehicleId,
        driverId: driverId,
        capacity: capacity,
        capacityUnitId: capacityUnitId,
        defaultProductId: defaultProductId,
      );
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  // Future<void> deleteRefillUnitImagesById(int? id) async {
  //   try {
  //     if (token == null) {
  //       throw Exception("No Token Found");
  //     }
  //     await restApi.deleteImagesById(token: 'Bearer $token', id: id);
  //     await getVehicleData();
  //   } catch (e) {
  //     if (e is DioException) {
  //       print('Dio Exception $e');
  //     }
  //   }
  // }
}
