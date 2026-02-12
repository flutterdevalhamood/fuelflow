import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class ProductController with ChangeNotifier {
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? productData;
  bool isLoading = false;
  final token = AuthRepo.token;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;

  Future<void> getProductData({bool loadMore = false}) async {
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
      final product = await restApi.getProductData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      if (product['IsSuccess'] == true) {
        final data = product['Data'] as List<dynamic>;
        if (data != null) {
          final newProduct =
              data.map((v) => v as Map<String, dynamic>).toList();

          if (loadMore) {
            productData ??= [];
            productData!.addAll(newProduct);
          } else {
            productData = newProduct;
          }
          hasMore = data.length == totalPages;
        } else {
          hasMore = false;
        }
      } else {
        print('Api call failed ${product['Message']}');
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
    getProductData(loadMore: true);
  }

  Future<void> getCustomerDropDown() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final dropDownData = await restApi.getCustomerDropDown('Bearer $token');
      if (dropDownData['IsSuccess'] == true) {
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

  Future<bool> registerProduct(String? name) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerProduct(token: 'Bearer $token', name: name);
      await getProductData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> updateProduct(int? id, String? name) async {
    if (token == null) {
      throw Exception("No Token Found");
    }
    try {
      await restApi.updateProduct(token: 'Bearer $token', id: id, name: name);
      await getProductData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
      return false;
    }
  }

  Future<void> deleteProduct(int? id, String? description) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteProduct(
        token: 'Bearer $token',
        id: id,
        deleteDescription: description,
      );
      await getProductData();
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
    }
  }
}
