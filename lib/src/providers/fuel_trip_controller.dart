import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelTripController with ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingResponse = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  List<Map<String, dynamic>>? assignedTripsData;
  Map<String, dynamic>? acceptedAssignmentData;
  String? errorMessage;

  Future<void> getAssignedTrips({bool loadMore = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      if (token == null) {
        throw Exception("No token found");
      }

      final assignedTrips = await restApi.getAssignedTrips(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      print('API Response: ${assignedTrips}');

      if (assignedTrips is Map<String, dynamic>) {
        if (assignedTrips['IsSuccess'] == true) {
          final data = assignedTrips['Data'] as List<dynamic>?;
          if (data != null) {
            final newAssignedData =
                data.map((v) => v as Map<String, dynamic>).toList();
            print('newAssignedData: $newAssignedData');

            if (loadMore) {
              assignedTripsData ??= [];
              assignedTripsData!.addAll(newAssignedData);
            } else {
              assignedTripsData = newAssignedData;
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          errorMessage = assignedTrips['Message'] ?? 'API call failed';
          print('API call failed: ${assignedTrips['Message']}');
        }
      } else {
        errorMessage = 'Unexpected API response format';
        print('Unexpected API response format');
      }
    } catch (e) {
      errorMessage = 'Failed to load assigned trips';
      print('Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAcceptedAssignments() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No token found");
      }

      final response = await restApi.getAcceptedAssignments(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      print('Accepted Assignments API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          acceptedAssignmentData = response['Data'] as Map<String, dynamic>?;
          print('acceptedAssignmentData: $acceptedAssignmentData');
        } else {
          errorMessage = response['Message'] ?? 'API call failed';
          print('API call failed: ${response['Message']}');
        }
      } else {
        errorMessage = 'Unexpected API response format';
        print('Unexpected API response format');
      }
    } catch (e) {
      errorMessage = 'Failed to load accepted assignments';
      print('Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getAssignedTrips(loadMore: true);
    }
  }

  Future<bool> postDriverResponse({
    required int assignmentId,
    required int driverId,
    required String response,
    String? reason,
  }) async {
    isSubmittingResponse = true;
    errorMessage = null;
    notifyListeners();

    try {
      final postDriverResponseData = await restApi.postSubmitDriverResponse(
        token: 'Bearer $token',
        assignmentId: assignmentId,
        driverId: driverId,
        response: response,
        reason: reason,
      );

      if (postDriverResponseData['IsSuccess'] == true) {
        // Remove the accepted/rejected trip from the list
        assignedTripsData?.removeWhere(
          (trip) => trip['assignment_id'] == assignmentId,
        );

        // If accepted, fetch the accepted assignment details
        if (response == 'accepted') {
          await getAcceptedAssignments();
        }

        isSubmittingResponse = false;
        notifyListeners();
        return true;
      } else {
        errorMessage =
            postDriverResponseData['Message'] ?? 'Failed to submit response';
        print('API call failed: ${postDriverResponseData['Message']}');
        isSubmittingResponse = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to submit response';
      if (e is DioException) {
        print("Dio Exception $e");
      }
      isSubmittingResponse = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearAcceptedAssignment() {
    acceptedAssignmentData = null;
    notifyListeners();
  }
}
