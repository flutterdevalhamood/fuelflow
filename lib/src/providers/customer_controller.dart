import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/repo/auth_repo.dart';

class CustomerController with ChangeNotifier {
  List<Map<String, dynamic>>? customerData;
  Map<String, dynamic>? customerRegister;
  bool isLoading = false;
  final token = AuthRepo.token;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;
  Future<void> getCustomerData({bool loadMore = false}) async {
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
      final customer = await restApi.getCustomerList(
        'Bearer $token',
        currentPage,
        totalPages,
      );
      if (customer is Map<String, dynamic>) {}
      if (customer['IsSuccess'] == true) {
        final data = customer['Data'] as List<dynamic>;
        if (data != null) {
          final newCustomers =
              data.map((v) => v as Map<String, dynamic>).toList();
          print('customerData $customerData');
          if (loadMore) {
            customerData ??= [];
            customerData!.add(newCustomers as Map<String, dynamic>);
          } else {
            customerData = newCustomers;
          }
          hasMore = data.length == totalPages;
        } else {
          hasMore = false;
        }
      } else {
        print('Api call failed ${customer['Message']}');
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
    if (!hasMore && !isLoading) {
      currentPage++;
      getCustomerData(loadMore: true);
    }
  }

  Future<bool> registerCustomer(
    String? name,
    String? representative,
    String? mobile,
    String? secondaryMobile,
    String? email,
    int? isAdmin,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerCustomer(
        token: 'Bearer $token',
        name: name,
        representative: representative,
        mobile: mobile,
        secondaryMobile: secondaryMobile,
        email: email,
        isAdmin: isAdmin,
      );
      await getCustomerData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> updateCustomer(
    int? id,
    String? name,
    String? representative,
    String? mobile,
    String? email,
  ) async {
    if (token == null) {
      throw Exception("No Token Found");
    }
    try {
      await restApi.updateCustomer(
        token: 'Bearer $token',
        id: id,
        name: name,
        representative: representative,
        mobile: mobile,
        email: email,
      );
      await getCustomerData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
      return false;
    }
  }

  Future<void> deleteCustomer(int? id, String? description) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteCustomer(
        token: 'Bearer $token',
        id: id,
        deleteDescription: description,
      );
      await getCustomerData();
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
    }
  }
}
