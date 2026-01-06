import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/repo/auth_repo.dart';

class UserRegistrationController with ChangeNotifier {
  List<Map<String, dynamic>>? userData;
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? driverData;
  List<Map<String, dynamic>>? rolesData;
  bool isLoading = false;
  final token = AuthRepo.token;
  bool hasMore = false;
  int currentPage = 1;
  final int pageLimit = 10;
  String? errorMessage;

  Future<void> getUsersData({bool loadMore = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }

      final users = await restApi.getAllUsers(
        'Bearer $token',
        currentPage,
        pageLimit,
      );

      if (users is Map<String, dynamic>) {
        if (users['IsSuccess'] == true) {
          final data = users['Data'] as List<dynamic>?;

          if (data != null && data.isNotEmpty) {
            final newUsers =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              userData ??= [];
              userData!.addAll(newUsers);
            } else {
              userData = newUsers;
            }

            hasMore = data.length == pageLimit;
          } else {
            hasMore = false;
            if (!loadMore) {
              userData = [];
            }
          }
        } else {
          errorMessage = users['Message'] ?? 'Failed to fetch users';
          print('Api call failed ${users['Message']}');
        }
      }
    } catch (e) {
      errorMessage = 'Error fetching users';
      if (e is DioException) {
        print('Dio Exception: ${e.message}');
        errorMessage = e.response?.data?['Message'] ?? e.message;
      }
      print('Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getUsersData(loadMore: true);
    }
  }

  Future<bool> postUserRegistration(
    String? name,
    String? email,
    String? password,
    int? roleId,
    int? driverId,
    int? customerId,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }

      final response = await restApi.postUserRegistration(
        token: 'Bearer $token',
        name: name,
        email: email,
        password: password,
        roleId: roleId,
        driverId: driverId,
        customerId: customerId,
      );

      if (response['IsSuccess'] == true) {
        await getUsersData();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = response['Message'] ?? 'Registration failed';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception: ${e.message}");
        errorMessage = e.response?.data?['Message'] ?? e.message;
      } else {
        errorMessage = e.toString();
      }
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getUsersBaseList() async {
    try {
      if (token == null) {
        throw Exception("No token found");
      }

      final userBaseListData = await restApi.getUsersBaseList(
        token: 'Bearer $token',
      );

      if (userBaseListData['IsSuccess'] == true) {
        final data = userBaseListData['Data'];

        customerData = List<Map<String, dynamic>>.from(data['customer'] ?? []);

        driverData = List<Map<String, dynamic>>.from(data['driver'] ?? []);

        rolesData = List<Map<String, dynamic>>.from(data['roles'] ?? []);

        notifyListeners();
      } else {
        errorMessage =
            userBaseListData['Message'] ?? 'Failed to fetch base list';
        print('API call failed: ${userBaseListData['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio error: ${e.message}');
        errorMessage = e.response?.data?['Message'] ?? e.message;
      }
      print('Error: $e');
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
