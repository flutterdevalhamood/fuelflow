import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class DriverController with ChangeNotifier {
  List<Map<String, dynamic>>? driverData;
  bool isLoading = false;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;

  Future<void> getDriverData({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();

    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      // Get fresh token from AuthRepo
      final token = AuthRepo.token;

      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      // Debug prints to verify authentication details
      print('=== Driver API Call Debug ===');
      print('Customer ID: ${AuthRepo.customerId}');
      print('User Role: ${AuthRepo.role}');
      print('User Name: ${AuthRepo.user}');
      print('Token exists: ${token.isNotEmpty}');
      print('Token starts with Bearer: ${token.startsWith('Bearer')}');
      print('=============================');

      final driver = await restApi.getDriverData(
        currentPage,
        totalPages,
        token.startsWith('Bearer')
            ? token
            : 'Bearer $token', // Ensure Bearer prefix
      );

      print('API Response: $driver');

      if (driver['IsSuccess'] == true) {
        final data = driver['Data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final newDriver = data.map((v) => v as Map<String, dynamic>).toList();
          print('Successfully fetched ${newDriver.length} drivers');

          if (loadMore) {
            driverData ??= [];
            driverData!.addAll(newDriver);
          } else {
            driverData = newDriver;
          }
          hasMore = data.length == totalPages;
        } else {
          print('No drivers found in response');
          if (!loadMore) {
            driverData = []; // Set empty list instead of null
          }
          hasMore = false;
        }
      } else {
        print('API call failed: ${driver['Message']}');
        print('Status Code: ${driver['StatusCode']}');
        if (!loadMore) {
          driverData = []; // Set empty list on failure
        }
        hasMore = false;
      }
    } catch (e) {
      print('Error in getDriverData: $e');
      if (e is DioException) {
        print('Dio Exception Details:');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Path: ${e.requestOptions.path}');
        print('Request Headers: ${e.requestOptions.headers}');
      }

      if (!loadMore) {
        driverData = []; // Set empty list on error
      }
      hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getDriverData(loadMore: true);
    }
  }

  Future<bool> registerDriver(
    String? name,
    String? mobile,
    int? customerId,
  ) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.registerDriver(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        name: name,
        mobile: mobile,
        customerId: customerId ?? AuthRepo.customerId,
      );

      // Refresh the driver list
      await getDriverData();
      return true;
    } catch (e) {
      print("Error in registerDriver: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
      return false;
    }
  }

  Future<bool> registerDriverForCustomer(
    String? name,
    String? mobile,
    int? customerId,
  ) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.superAdminCreateDriver(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        name: name,
        mobile: mobile,
        customerId: customerId,
      );

      // Refresh the driver list
      await getDriverData();
      return true;
    } catch (e) {
      print("Error in registerDriverForCustomer: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
      return false;
    }
  }

  Future<bool> updateDriver(int? id, String? name, String? mobile) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.updateDriver(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        id: id,
        name: name,
        mobile: mobile,
      );

      await getDriverData();
      return true;
    } catch (e) {
      print('Error in updateDriver: $e');
      if (e is DioException) {
        print('Dio Exception: ${e.response?.data}');
      }
      return false;
    }
  }

  Future<void> deleteDriver(int? id, String? description) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.deleteDriver(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        id: id,
        deleteDescription: description,
      );

      await getDriverData();
    } catch (e) {
      print("Error in deleteDriver: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
    }
  }
}
