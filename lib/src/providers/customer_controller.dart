import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/repo/auth_repo.dart';

class CustomerController with ChangeNotifier {
  List<Map<String, dynamic>>? customerData;
  Map<String, dynamic>? customerRegister;
  bool isLoading = false;
  final token = AuthRepo.token;
  Future<void> getCustomerData() async {
    isLoading = true;
    notifyListeners();
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final customer = await restApi.getCustomerList('Bearer $token');
      if (customer['IsSuccess'] == true) {
        final data = customer['Data'] as List<dynamic>;
        if (data != null) {
          customerData = data.map((v) => v as Map<String, dynamic>).toList();
          print('customerData $customerData');
        } else {
          print('No data found');
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

  Future<bool> registerCustomer(
    String? name,
    String? representative,
    String? mobile,
    String? email,
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
        email: email,
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
