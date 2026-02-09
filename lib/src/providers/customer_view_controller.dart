import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CustomerViewController with ChangeNotifier {
  List<Map<String, dynamic>>? customerViewData;
  bool isLoading = false;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;

  Future<void> getCustomerViewData({bool loadMore = false}) async {
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

      final customerView = await restApi.getDriverData(
        currentPage,
        totalPages,
        token.startsWith('Bearer')
            ? token
            : 'Bearer $token', // Ensure Bearer prefix
      );

      print('API Response: $customerView');

      if (customerView['IsSuccess'] == true) {
        final data = customerView['Data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final newCustomerView =
              data.map((v) => v as Map<String, dynamic>).toList();
          print(
            'Successfully fetched ${newCustomerView.length} newCustomerView',
          );

          if (loadMore) {
            customerViewData ??= [];
            customerViewData!.addAll(newCustomerView);
          } else {
            customerViewData = newCustomerView;
          }
          hasMore = data.length == totalPages;
        } else {
          print('No customerview data found in response');
          if (!loadMore) {
            customerViewData = []; // Set empty list instead of null
          }
          hasMore = false;
        }
      } else {
        print('API call failed: ${customerView['Message']}');
        print('Status Code: ${customerView['StatusCode']}');
        if (!loadMore) {
          customerViewData = []; // Set empty list on failure
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
        customerViewData = []; // Set empty list on error
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
      getCustomerViewData(loadMore: true);
    }
  }
}
