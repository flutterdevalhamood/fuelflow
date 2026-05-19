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

  int completedCurrentPage = 1;
  final int completedTotalPages = 10;
  bool hasMoreCompleted = true;
  List<Map<String, dynamic>>? completedAssignmentsData;

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

      final assignedTrips = await restApi.getAssignedTrips(
        currentPage,
        totalPages,
        'Bearer $currentToken',
      );

      if (assignedTrips is Map<String, dynamic>) {
        if (assignedTrips['IsSuccess'] == true) {
          final data = assignedTrips['Data'] as List<dynamic>?;
          if (data != null) {
            final newAssignedData =
                data.map((v) => v as Map<String, dynamic>).toList();

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
        }
      } else {
        errorMessage = 'Unexpected API response format';
      }
    } catch (e) {
      errorMessage = 'Failed to load assigned trips';

      if (e is DioException) {
        print('Dio error: ${e.message}');
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

      final response = await restApi.getAcceptedAssignments(
        currentPage,
        totalPages,
        'Bearer $currentToken',
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          acceptedAssignmentData = response['Data'] as Map<String, dynamic>?;
        } else {
          errorMessage = response['Message'] ?? 'API call failed';

          acceptedAssignmentData = null;
        }
      } else {
        errorMessage = 'Unexpected API response format';

        acceptedAssignmentData = null;
      }
    } catch (e) {
      errorMessage = 'Failed to load accepted assignments';
      acceptedAssignmentData = null;

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

  Future<void> getCompletedAssignments({bool loadMore = false}) async {
    if (!loadMore) {
      completedAssignmentsData = null;
      completedCurrentPage = 1;
      hasMoreCompleted = true;
    }

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final currentToken = token;

      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found - user not authenticated");
      }

      print(
        '🔑 Fetching completed assignments - Page: $completedCurrentPage with token: ${currentToken.substring(0, 20)}...',
      );

      final response = await restApi.getCompletedAssignments(
        completedCurrentPage,
        completedTotalPages,
        'Bearer $currentToken',
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final data = response['Data'] as List<dynamic>?;
          if (data != null) {
            final newCompletedData =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              completedAssignmentsData ??= [];
              completedAssignmentsData!.addAll(newCompletedData);
            } else {
              completedAssignmentsData = newCompletedData;
            }
            hasMoreCompleted = data.length == completedTotalPages;
          } else {
            hasMoreCompleted = false;
            if (!loadMore) {
              completedAssignmentsData = [];
            }
          }
        } else {
          errorMessage = response['Message'] ?? 'API call failed';
        }
      } else {
        errorMessage = 'Unexpected API response format';
      }
    } catch (e) {
      errorMessage = 'Failed to load completed assignments';
      print('❌ Exception: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMoreCompletedAssignments() {
    if (hasMoreCompleted && !isLoading) {
      completedCurrentPage++;
      getCompletedAssignments(loadMore: true);
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

        isSubmittingResponse = false;
        notifyListeners();
        return true;
      } else {
        errorMessage =
            postDriverResponseData['Message'] ?? 'Failed to submit response';

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

      final response = await restApi.postVehicleNotAvailable(
        token: 'Bearer $currentToken',
        vehicleId: vehicleId.toList(), // ✅ LIST
        description: description,
        tripStopId: tripStopId,
      );

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

      if (e is DioException) {
        debugPrint('Dio error: ${e.message}');
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

  void clearCompletedAssignments() {
    completedAssignmentsData = null;
    completedCurrentPage = 1;
    hasMoreCompleted = true;
    notifyListeners();
  }

  void clearAllData() {
    assignedTripsData = null;
    acceptedAssignmentData = null;
    completedAssignmentsData = null;
    errorMessage = null;
    currentPage = 1;
    hasMore = true;
    completedCurrentPage = 1;
    hasMoreCompleted = true;
    isLoading = false;
    isSubmittingResponse = false;
    notifyListeners();
  }

  // Add these fields
  List<Map<String, dynamic>>? notificationsData;
  int unreadCount = 0;
  int notificationPage = 1;
  final int notificationLimit = 10;
  bool hasMoreNotifications = true;

  Future<void> getNotifications({bool loadMore = false}) async {
    if (!loadMore) {
      notificationsData = null;
      notificationPage = 1;
      hasMoreNotifications = true;
    }

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      final currentToken = token;
      if (currentToken == null || currentToken.isEmpty) {
        throw Exception("No token found");
      }

      final response = await restApi.getNotifications(
        'Bearer $currentToken',
        notificationPage,
        notificationLimit,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null) {
          final newData = data.map((v) => v as Map<String, dynamic>).toList();
          if (loadMore) {
            notificationsData ??= [];
            notificationsData!.addAll(newData);
          } else {
            notificationsData = newData;
          }
          hasMoreNotifications = data.length == notificationLimit;
        } else {
          hasMoreNotifications = false;
          if (!loadMore) notificationsData = [];
        }
      } else {
        errorMessage = response['Message'] ?? 'Failed to load notifications';
      }
    } catch (e) {
      errorMessage = 'Failed to load notifications';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final currentToken = token;
      if (currentToken == null || currentToken.isEmpty) return;

      final response = await restApi.getUnreadCount(
        token: 'Bearer $currentToken',
      );
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        unreadCount = response['Data'] as int? ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<bool> markNotificationAsRead(int id) async {
    try {
      final currentToken = token;
      if (currentToken == null || currentToken.isEmpty) return false;

      final response = await restApi.getNotificationMarkAsRead(
        token: 'Bearer $currentToken',
        id: id, // PASS ACTUAL ID HERE
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final index = notificationsData?.indexWhere((n) => n['id'] == id);
        if (index != null && index >= 0) {
          notificationsData![index]['is_read'] = true;
        }
        if (unreadCount > 0) unreadCount--;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
    return false;
  }

  void loadMoreNotifications() {
    if (hasMoreNotifications && !isLoading) {
      notificationPage++;
      getNotifications(loadMore: true);
    }
  }
}
