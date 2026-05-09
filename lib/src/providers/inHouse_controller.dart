import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class InHouseDeliveryController with ChangeNotifier {
  List<Map<String, dynamic>>? vehicleData;
  List<Map<String, dynamic>>? filteredVehicleData;
  bool isLoading = false;
  bool hasMore = true;

  int currentPage = 1;
  final int pageSize = 100;
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  Future<void> getAdminVehicles({bool loadMore = false}) async {
    if (isLoading) return;

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

      final response = await restApi.paginateCustomerVehicles(
        currentPage,
        pageSize,
        token.startsWith('Bearer') ? token : 'Bearer $token',
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null) {
          final newVehicles =
              data.map((v) => v as Map<String, dynamic>).toList();

          if (loadMore) {
            vehicleData ??= [];
            vehicleData!.addAll(newVehicles);
          } else {
            vehicleData = newVehicles;
          }

          hasMore = data.length == pageSize;
        } else {
          if (!loadMore) vehicleData = [];
          hasMore = false;
        }
      } else {
        if (!loadMore) vehicleData = [];
        hasMore = false;
      }
    } catch (e) {
      print('Exception fetching admin vehicles: $e');
      if (e is DioException) print('Dio error: ${e.message}');
      if (!loadMore) vehicleData = [];
      hasMore = false;
    } finally {
      _applySearch();
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getAdminVehicles(loadMore: true);
    }
  }

  void searchVehicles(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (vehicleData == null) {
      filteredVehicleData = null;
      return;
    }
    if (_searchQuery.isEmpty) {
      filteredVehicleData = List.from(vehicleData!);
    } else {
      filteredVehicleData =
          vehicleData!.where((vehicle) {
            final plateNo =
                (vehicle['plate_no'] ?? '').toString().toLowerCase();
            final customerName =
                (vehicle['customer']?['Name'] ?? '').toString().toLowerCase();
            return plateNo.contains(_searchQuery) ||
                customerName.contains(_searchQuery);
          }).toList();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }
}
