import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CustomerSiteController with ChangeNotifier {
  List<Map<String, dynamic>>? customerSiteData;
  bool isLoading = false;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;

  Future<void> getCustomerSiteData({bool loadMore = false}) async {
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

      final customerSites = await restApi.getCustomerSite(
        currentPage,
        totalPages,
        token.startsWith('Bearer')
            ? token
            : 'Bearer $token', // Ensure Bearer prefix
      );

      print('API Response: $customerSites');

      if (customerSites['IsSuccess'] == true) {
        final data = customerSites['Data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final newCustomerSites =
              data.map((v) => v as Map<String, dynamic>).toList();
          print(
            'Successfully fetched ${newCustomerSites.length} customer sites',
          );

          if (loadMore) {
            customerSiteData ??= [];
            customerSiteData!.addAll(newCustomerSites);
          } else {
            customerSiteData = newCustomerSites;
          }
          hasMore = data.length == totalPages;
        } else {
          print('No customer sites found in response');
          if (!loadMore) {
            customerSiteData = []; // Set empty list instead of null
          }
          hasMore = false;
        }
      } else {
        print('API call failed: ${customerSites['Message']}');
        print('Status Code: ${customerSites['StatusCode']}');
        if (!loadMore) {
          customerSiteData = []; // Set empty list on failure
        }
        hasMore = false;
      }
    } catch (e) {
      print('Error in getCustomerSiteData: $e');
      if (e is DioException) {
        print('Dio Exception Details:');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request Path: ${e.requestOptions.path}');
        print('Request Headers: ${e.requestOptions.headers}');
      }

      if (!loadMore) {
        customerSiteData = []; // Set empty list on error
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
      getCustomerSiteData(loadMore: true);
    }
  }

  Future<bool> registerCustomerSites(
    int? customerId,
    String? name,
    String? description,
    String? latitude,
    String? longitude,
  ) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.postCustomerSite(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        customerId: customerId ?? AuthRepo.customerId,
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
      );

      // Refresh the customer site list
      await getCustomerSiteData();
      return true;
    } catch (e) {
      print("Error in registerCustomerSites: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
      return false;
    }
  }

  Future<bool> updateCustomerSites(
    int? customerId,
    String? name,
    String? description,
    String? latitude,
    String? longitude,
    int? id,
  ) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.updateCustomerSite(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        customerId: customerId ?? AuthRepo.customerId,
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        id: id,
      );

      await getCustomerSiteData();
      return true;
    } catch (e) {
      print('Error in updateCustomerSites: $e');
      if (e is DioException) {
        print('Dio Exception: ${e.response?.data}');
      }
      return false;
    }
  }

  Future<void> deleteCustomerSites(int? id, String? description) async {
    try {
      final token = AuthRepo.token;
      if (token == null || token.isEmpty) {
        throw Exception("No Token Found");
      }

      await restApi.deleteCustomerSite(
        token: token.startsWith('Bearer') ? token : 'Bearer $token',
        id: id,
        deleteDescription: description,
      );

      await getCustomerSiteData();
    } catch (e) {
      print("Error in deleteCustomerSites: $e");
      if (e is DioException) {
        print("Dio Exception: ${e.response?.data}");
      }
    }
  }
}
