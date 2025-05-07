import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:sample/src/data/rest_client.dart';
import 'package:sample/src/repo/auth_repo.dart';

class AssignedRefillingUnitController with ChangeNotifier {
  List<Map<String, dynamic>>? assignedUnits;
  bool isLoading = false;
  final token = AuthRepo.token;
  int? customerId;
  String? errorMessage;

  Future<void> getAssignedForCustomer() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }

      if (customerId == null) {
        throw Exception("Customer ID is required");
      }

      final assignedData = await restApi.getAssignedUnitForCustomer(
        customerId: customerId!,
        token: 'Bearer $token',
      );

      if (assignedData['IsSuccess'] == true) {
        final data = assignedData['Data'] as List<dynamic>;
        assignedUnits = data.map((v) => v as Map<String, dynamic>).toList();
        print('Assigned units fetched: ${assignedUnits?.length}');
      } else {
        errorMessage =
            assignedData['Message'] ?? 'Failed to fetch assigned units';
        print('API call failed: $errorMessage');
      }
    } catch (e) {
      if (e is DioException) {
        errorMessage = 'Network error: ${e.message}';
        print('Dio Exception: $e');
      } else {
        errorMessage = 'Error: ${e.toString()}';
        print('Error: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
