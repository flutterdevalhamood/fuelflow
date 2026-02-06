import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/firebase_services.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../config/messages.dart';
import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
import '../util/circle_progress.dart';
import '../util/snack.dart';

enum LoginType { admin, operator, customer }

class AuthController with ChangeNotifier {
  LoginType loginType = LoginType.admin;
  final FirebaseService _firebaseService = FirebaseService();

  set setLoginType(LoginType type) {
    loginType = type;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    showCircle();

    try {
      print('Attempting login...');

      // Get FCM token
      String? deviceToken = await FirebaseService().getFCMToken();

      if (deviceToken == null) {
        log('Warning: FCM token is null, proceeding without device token');
        // You might want to retry getting the token or show a warning
        // For now, we'll proceed with the login
      } else {
        log('FCM Token retrieved: $deviceToken');
      }

      log('Sending login request with device token: ${deviceToken ?? "null"}');

      print('═══════════════════════════════════════');
      print('LOGIN REQUEST PARAMETERS:');
      print('Email: $email');
      print('Password: ${password.isNotEmpty ? "***" : "empty"}');
      print('Device Token: $deviceToken');
      print('Device Token is null: ${deviceToken == null}');
      print('Device Token is empty: ${deviceToken?.isEmpty ?? "null"}');
      print('Device Token length: ${deviceToken?.length ?? 0}');
      print('═══════════════════════════════════════');

      final loginResponse = await restApi.login(
        email: email,
        password: password,
        deviceToken: deviceToken, // Pass the device token to your API
      );

      if (loginResponse.IsSuccess == true) {
        log(
          'Login successful: ${JsonEncoder.withIndent("\t").convert(loginResponse)}',
        );

        // Set new auth data with the response
        AuthRepo.token = loginResponse.Token; // Set the new token first
        AuthRepo.loginType = loginType;
        AuthRepo.role = loginResponse.Data?.roles?.Name;
        AuthRepo.user = loginResponse.Data?.name;
        AuthRepo.customerId = loginResponse.Data?.customer?.id;
        AuthRepo.driverId = loginResponse.Data?.driver?.id;

        print('New token set: ${AuthRepo.token}');
        print('Customer ID: ${AuthRepo.customerId}');
        print('Login type: ${AuthRepo.loginType}');
        print('Role: ${AuthRepo.role}');
        print('Driver ID: ${AuthRepo.driverId}');

        // Verify token is properly set
        if (AuthRepo.token != null && AuthRepo.token!.isNotEmpty) {
          NavigationService().pushNavigation(
            Screenroutes.dashboard,
            arguments: {'role': loginResponse.Data?.roles?.Name},
          );
        } else {
          showErrorSnack('Failed to set authentication token');
        }
      } else {
        showErrorSnack(Messages.authenticationFailure);
      }
    } catch (e) {
      log('Login error: $e');
      if (e is DioException) {
        log("DioException: ${e.message}", stackTrace: e.stackTrace);
        if (e.response?.statusCode == 401) {
          showErrorSnack('Invalid credentials');
        } else {
          showErrorSnack('Network error occurred');
        }
      } else {
        log("General error: $e", stackTrace: e is Error ? e.stackTrace : null);
        showErrorSnack(Messages.authenticationFailure);
      }
    }

    removeCircle();
  }

  // Method to handle logout
  Future<void> logout() async {
    showCircle();

    try {
      // Get the current device token before clearing auth data
      String? deviceToken = await FirebaseService().getFCMToken();

      // Get user ID or other identifier - adjust based on your user model
      String? userId =
          AuthRepo.customerId?.toString() ?? AuthRepo.driverId?.toString();

      // Get the auth token before clearing
      String? authToken = AuthRepo.token;

      log('═══════════════════════════════════════');
      log('LOGOUT REQUEST PARAMETERS:');
      log('User ID: $userId');
      log('Device Token: $deviceToken');
      log('Auth Token: ${authToken?.substring(0, 20)}...');
      log('═══════════════════════════════════════');

      // Call logout API with authorization token
      final response = await restApi.logout(
        token: authToken != null ? 'Bearer $authToken' : null,
        id: userId,
        deviceToken: deviceToken,
      );

      log('Logout API response: $response');
      log('Logout API call successful');

      // Only proceed with cleanup and navigation if API call was successful
      try {
        // Delete FCM token locally
        await FirebaseService().deleteToken();
        log('FCM token deleted successfully');
      } catch (tokenError) {
        log('Warning: Error deleting FCM token: $tokenError');
        // Continue with logout even if token deletion fails
      }

      // Clear local auth data
      AuthRepo.logOut();
      log('Local auth data cleared');

      removeCircle();

      // Show success message
      showSuccessSnack('Logged out successfully');

      // Navigate to login screen only after successful logout
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

      log('Navigation to login screen completed');
    } catch (e) {
      log('Logout API error: $e');
      removeCircle();

      // Handle specific error cases
      if (e is DioException) {
        log(
          "DioException during logout: ${e.message}",
          stackTrace: e.stackTrace,
        );

        // Check if it's a network error or server error
        if (e.response?.statusCode == 401) {
          // Token might be expired, still clear local data and navigate
          log('Token expired or invalid, clearing local data anyway');
          _performLocalLogout();
        } else if (e.response?.statusCode != null) {
          // Server responded with an error
          showErrorSnack('Logout failed. Please try again.');
        } else {
          // Network error
          showErrorSnack('Network error. Please check your connection.');
        }
      } else {
        log(
          "General error during logout: $e",
          stackTrace: e is Error ? e.stackTrace : null,
        );
        showErrorSnack('An error occurred during logout');
      }

      // DO NOT navigate to login screen on error
      // User should retry or we should handle it differently based on requirements
    }
  }

  // Helper method to perform local logout when API fails but we still want to clear data
  Future<void> _performLocalLogout() async {
    try {
      // Delete FCM token locally
      await FirebaseService().deleteToken();
      log('FCM token deleted (local logout)');
    } catch (tokenError) {
      log('Error deleting FCM token during local logout: $tokenError');
    }

    // Clear local auth data
    AuthRepo.logOut();
    log('Local auth data cleared (local logout)');

    // Navigate to login screen
    NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

    showSuccessSnack('Logged out locally');
  }

  // Optional: Force logout method that clears local data regardless of API response
  // Use this only when you want to force logout (e.g., user explicitly requests it after error)
  Future<void> forceLogout() async {
    showCircle();

    try {
      // Attempt API call but don't wait for success
      String? deviceToken = await FirebaseService().getFCMToken();
      String? userId =
          AuthRepo.customerId?.toString() ?? AuthRepo.driverId?.toString();
      String? authToken = AuthRepo.token;

      restApi
          .logout(
            token: authToken != null ? 'Bearer $authToken' : null,
            id: userId,
            deviceToken: deviceToken,
          )
          .catchError((error) {
            log('Force logout: API call failed but continuing: $error');
          });
    } catch (e) {
      log('Force logout: Error during API call: $e');
    }

    // Clear local data regardless of API response
    await _performLocalLogout();
    removeCircle();
  }

  // Method to check if user is currently authenticated
  bool get isAuthenticated {
    return AuthRepo.isAuthenticated;
  }

  // Method to update device token (useful if token refreshes while app is running)
  Future<void> updateDeviceToken() async {
    try {
      String? deviceToken = await FirebaseService().getFCMToken();

      if (deviceToken != null && AuthRepo.isAuthenticated) {
        // Call API to update device token on server
        // await restApi.updateDeviceToken(deviceToken: deviceToken);
        log('Device token updated: $deviceToken');
      }
    } catch (e) {
      log('Error updating device token: $e');
    }
  }
}
