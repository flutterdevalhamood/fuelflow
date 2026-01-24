import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class FuelTripController with ChangeNotifier {
  bool isLoading = false;
  bool isSubmittingResponse = false;

  // ✅ FIXED: Use getter to always fetch fresh token from AuthRepo
  // Instead of: final token = AuthRepo.token;
  String? get token => AuthRepo.token;

  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  List<Map<String, dynamic>>? assignedTripsData;
  Map<String, dynamic>? acceptedAssignmentData;
  String? errorMessage;

  Future<void> getAssignedTrips({bool loadMore = false}) async {
    if (!loadMore) {
      assignedTripsData = null;
      currentPage = 1;
      hasMore = true;
    }

    errorMessage = null;
    isLoading = true;
    notifyListeners(); // Notify UI immediately

    try {
      // Get fresh token each time
      final currentToken = token;

      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found - user not authenticated");
      }

      print(
        '🔑 Making assigned trips request with token: ${currentToken.substring(0, 20)}...',
      );

      final assignedTrips = await restApi.getAssignedTrips(
        currentPage,
        totalPages,
        'Bearer $currentToken',
      );
      print('API Response: $assignedTrips');

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
      print('❌ Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        print('Response: ${e.response?.data}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAcceptedAssignments() async {
    // ✅ FIXED: Clear old data BEFORE making API call
    acceptedAssignmentData = null;
    errorMessage = null;

    isLoading = true;
    notifyListeners(); // Notify UI immediately to show loading state

    try {
      // Get fresh token each time
      final currentToken = token;

      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found - user not authenticated");
      }

      print(
        '🔑 Fetching accepted assignments with token: ${currentToken.substring(0, 20)}...',
      );
      print('Current page: $currentPage, Total pages: $totalPages');

      final response = await restApi.getAcceptedAssignments(
        currentPage,
        totalPages,
        'Bearer $currentToken',
      );
      print('Accepted Assignments API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          acceptedAssignmentData = response['Data'] as Map<String, dynamic>?;
          print('✅ acceptedAssignmentData: $acceptedAssignmentData');
        } else {
          errorMessage = response['Message'] ?? 'API call failed';
          print('❌ API call failed: ${response['Message']}');
          acceptedAssignmentData = null;
        }
      } else {
        errorMessage = 'Unexpected API response format';
        print('❌ Unexpected API response format');
        acceptedAssignmentData = null;
      }
    } catch (e) {
      errorMessage = 'Failed to load accepted assignments';
      acceptedAssignmentData = null;
      print('❌ Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        print('Response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
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
      // Get fresh token each time
      final currentToken = token;

      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found - user not authenticated");
      }

      final postDriverResponseData = await restApi.postSubmitDriverResponse(
        token: 'Bearer $currentToken',
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

  Future<bool> postVehicleNotAvailable({
    required List<int> vehicleId,
    required String description,
    required int tripStopId,
  }) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final currentToken = token;

      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found - user not authenticated");
      }

      debugPrint(
        '🔑 Marking vehicles unavailable: $vehicleId, Stop: $tripStopId',
      );

      final response = await restApi.postVehicleNotAvailable(
        token: 'Bearer $currentToken',
        vehicleId: vehicleId, // ✅ LIST
        description: description,
        tripStopId: tripStopId,
      );

      debugPrint('📦 API Response: $response');

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          isLoading = false;
          notifyListeners();
          return true;
        } else {
          errorMessage =
              response['Message'] ?? 'Failed to mark vehicles as unavailable';
        }
      } else {
        errorMessage = 'Unexpected API response format';
      }
    } catch (e) {
      errorMessage = 'Failed to mark vehicle(s) as unavailable';
      debugPrint('❌ Exception: $e');

      if (e is DioException) {
        debugPrint('Dio error: ${e.message}');
        debugPrint('Response: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return false;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearAcceptedAssignment() {
    acceptedAssignmentData = null;
    notifyListeners();
  }

  void clearAllData() {
    assignedTripsData = null;
    acceptedAssignmentData = null;
    errorMessage = null;
    currentPage = 1;
    hasMore = true;
    isLoading = false;
    isSubmittingResponse = false;
    notifyListeners();
  }
}
