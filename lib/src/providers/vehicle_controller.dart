import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class VehicleController with ChangeNotifier {
  List<Map<String, dynamic>>? vehicleData;
  List<Map<String, dynamic>>? vehicleTypeData;
  List<Map<String, dynamic>>? unitData;
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? customerSiteData;
  bool isLoading = false;
  bool isLoadingCustomerSites = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;

  Future<void> getVehicleData({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();
    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No token found");
      }
      final vehicle = await restApi.getVehicleData(
        currentPage,
        totalPages,
        token.startsWith('Bearer') ? token : 'Bearer $token',
      );

      if (vehicle is Map<String, dynamic>) {
        if (vehicle['IsSuccess'] == true) {
          final data = vehicle['Data'] as List<dynamic>?;
          if (data != null) {
            final newVehicles =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              vehicleData ??= [];
              vehicleData!.addAll(newVehicles);
            } else {
              vehicleData = newVehicles;
            }
            hasMore = data.length == totalPages;
          } else {
            if (!loadMore) {
              vehicleData = [];
            }
            hasMore = false;
          }
        } else {
          if (!loadMore) {
            vehicleData = [];
          }
          hasMore = false;
        }
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
      if (!loadMore) {
        vehicleData = [];
      }
      hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {}
    currentPage++;
    getVehicleData(loadMore: true);
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

  Future<void> getCustomerSites(int? customerId) async {
    if (customerId == null) {
      customerSiteData = [];
      notifyListeners();
      return;
    }

    isLoadingCustomerSites = true;
    customerSiteData = null;
    notifyListeners();

    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No token found");
      }

      final response = await restApi.getCustomerSitesOfCustomer(
        customerId: customerId,
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final data = response['Data'] as List<dynamic>?;
          if (data != null && data.isNotEmpty) {
            // Convert lowercase 'name' to uppercase 'Name' for consistency
            customerSiteData =
                data.map((site) {
                  final siteMap = site as Map<String, dynamic>;
                  return {
                    'id': siteMap['id'],
                    'Name': siteMap['name'], // Convert 'name' to 'Name'
                    'customer_id': siteMap['customer_id'],
                  };
                }).toList();
          } else {
            customerSiteData = [];
          }
        } else {
          customerSiteData = [];
        }
      } else {
        customerSiteData = [];
      }
    } catch (e, stackTrace) {
      print('Exception fetching customer sites: $e');
      print('Stack trace: $stackTrace');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
      customerSiteData = [];
    } finally {
      isLoadingCustomerSites = false;
      notifyListeners();
    }
  }

  Future<bool> registerVehicle(
    String? plateNumber,
    String? capacity,
    String? description,
    int? vehicleTypeId,
    int? capacityUnitId,
    int? customerId,
    int? customerSiteId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerVehicle(
        token: 'Bearer $token',
        platNumber: plateNumber,
        capacity: capacity,
        description: description,
        vehicleTypeId: vehicleTypeId,
        capacityUnitId: capacityUnitId,
        customerId: customerId,
        customerSiteId: 1,
      );
      await getVehicleData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<void> deleteVehicle(int? id, String? descriptionText) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteVehicle(
        token: 'Bearer $token',
        id: id,
        deleteDescription: descriptionText,
      );
      await getVehicleData();
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
      await restApi.deleteImagesById(token: 'Bearer $token', id: id);
      await getVehicleData();
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<void> editVehicleData(
    int? id,
    String? plateNumber,
    String? description,
    String? capacity,
    int? vehicleTypeId,
    int? capacityUnitId,
    int? customerId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.editVehicleData(
        token: 'Bearer $token',
        id: id,
        plate_no: plateNumber,
        description: description,
        capacity: capacity,
        vehicle_type_id: vehicleTypeId,
        capacity_unit_id: capacityUnitId,
        customerId: customerId,
      );
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    }
  }

  Future<bool> registerVehicleForCustomer(
    String? plateNumber,
    int? vehicleTypeId,
    String? capacity,
    String? description,
    int? capacityUnitId,
    int? customerId,
    int? customerSiteId,
  ) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.superAdminCreateVehicle(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        platNumber: plateNumber,
        vehicleTypeId: vehicleTypeId,
        capacity: capacity,
        description: description,
        capacityUnitId: capacityUnitId,
        customerId: customerId,
        customerSiteId: customerSiteId,
      );

      await getVehicleData();
      return true;
    } catch (e) {
      print("Error in registerVehicleForCustomer: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
      return false;
    }
  }

  Future<bool> uploadVehiclePictures(
    List<MultipartFile>? files,
    String? id,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final response = await restApi.uploadVehiclePictures(
        token: 'Bearer $token',
        files: files,
        id: id,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          return true;
        } else {
          return false;
        }
      } else {
        print('Unexpected API response format');
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> toggleVehicleStatus(int? id) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.toggleVehicleStatus(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        id: id,
      );

      await getVehicleData();
    } catch (e) {
      print("Error in vehicle: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
    }
  }
}
