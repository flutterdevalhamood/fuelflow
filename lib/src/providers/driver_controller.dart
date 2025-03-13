import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class DriverController with ChangeNotifier {
  List<Map<String, dynamic>>? driverData;
  bool isLoading = false;
  final token = AuthRepo.token;
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
      if (token == null) {
        throw Exception("No Token Found");
      }
      final driver = await restApi.getDriverData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      if (driver['IsSuccess'] == true) {
        final data = driver['Data'] as List<dynamic>;
        if (data != null) {
          final newDriver = data.map((v) => v as Map<String, dynamic>).toList();
          print('customerData $driverData');
          if (loadMore) {
            driverData ??= [];
            driverData!.addAll(newDriver);
          } else {
            driverData = newDriver;
          }
          hasMore = data.length == totalPages;
        } else {
          hasMore = false;
        }
      } else {
        print('Api call failed ${driver['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {}
    currentPage++;
    getDriverData(loadMore: true);
  }

  Future<bool> registerDriver(String? name, String? mobile) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerDriver(
        token: 'Bearer $token',
        name: name,
        mobile: mobile,
      );
      await getDriverData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> updateDriver(int? id, String? name, String? mobile) async {
    if (token == null) {
      throw Exception("No Token Found");
    }
    try {
      await restApi.updateDriver(
        token: 'Bearer $token',
        id: id,
        name: name,
        mobile: mobile,
      );
      await getDriverData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
      return false;
    }
  }

  Future<void> deleteDriver(int? id, String? description) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteDriver(
        token: 'Bearer $token',
        id: id,
        deleteDescription: description,
      );
      await getDriverData();
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
    }
  }
}
