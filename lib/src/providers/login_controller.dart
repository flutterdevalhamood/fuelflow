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
      log('═══════════════════════════════════════');
      log('STARTING LOGIN PROCESS');
      log('═══════════════════════════════════════');

      // CRITICAL FIX: Ensure Firebase is initialized before getting token
      if (!_firebaseService.isInitialized) {
        log('⚠️ Firebase not initialized, initializing now...');
        await _firebaseService.initialize();
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Get FCM token with retry logic
      String? deviceToken = await _getFCMTokenWithRetry();

      log('═══════════════════════════════════════');
      log('LOGIN REQUEST PARAMETERS:');
      log('Email: $email');
      log('Password: ${password.isNotEmpty ? "***" : "empty"}');
      log('Device Token: $deviceToken');
      log('═══════════════════════════════════════');

      final loginResponse = await restApi.login(
        email: email,
        password: password,
        deviceToken: deviceToken,
      );

      if (loginResponse.IsSuccess == true) {
        log('✅ Login successful');
        log('Response: ${JsonEncoder.withIndent("\t").convert(loginResponse)}');

        // Set new auth data with the response
        AuthRepo.token = loginResponse.Token;
        AuthRepo.loginType = loginType;
        AuthRepo.role = loginResponse.Data?.roles?.Name;
        AuthRepo.user = loginResponse.Data?.name;
        AuthRepo.customerId = loginResponse.Data?.customer?.id;
        AuthRepo.driverId = loginResponse.Data?.driver?.id;

        // NEW: Save customer data if available
        if (loginResponse.Data?.customer != null) {
          AuthRepo.setCustomerData(
            name: loginResponse.Data?.customer?.Name,
            email: loginResponse.Data?.customer?.email,
            mobile: loginResponse.Data?.customer?.mobile,
            representative: loginResponse.Data?.customer?.representative,
            secondaryMobile: loginResponse.Data?.customer?.secondary_mobile,
          );

          log('✅ Customer data saved:');
          log('Name: ${AuthRepo.customerName}');
          log('Email: ${AuthRepo.customerEmail}');
          log('Mobile: ${AuthRepo.customerMobile}');
        }

        log('Token set: ${AuthRepo.token != null ? "✅" : "❌"}');
        log('Customer ID: ${AuthRepo.customerId}');
        log('Driver ID: ${AuthRepo.driverId}');
        log('Role: ${AuthRepo.role}');

        // Verify token is properly set
        if (AuthRepo.token != null && AuthRepo.token!.isNotEmpty) {
          removeCircle();
          NavigationService().pushNavigation(
            Screenroutes.dashboard,
            arguments: {'role': loginResponse.Data?.roles?.Name},
          );
        } else {
          removeCircle();
          showErrorSnack('Failed to set authentication token');
        }
      } else {
        removeCircle();
        showErrorSnack(loginResponse.Message ?? Messages.authenticationFailure);
      }
    } catch (e, stackTrace) {
      log('❌ Login error: $e');
      removeCircle();

      if (e is DioException) {
        log("DioException: ${e.message}");
        log("Response: ${e.response?.data}");
        log("Status code: ${e.response?.statusCode}");

        if (e.response?.statusCode == 401) {
          showErrorSnack(
            'Invalid credentials. Please check your email and password.',
          );
        } else if (e.response?.statusCode == 422) {
          showErrorSnack('Invalid input. Please check your details.');
        } else if (e.response?.statusCode == 500) {
          showErrorSnack('Server error. Please try again later.');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          showErrorSnack('Connection timeout. Please check your internet.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          showErrorSnack('Server is taking too long to respond.');
        } else {
          showErrorSnack('Network error occurred. Please try again.');
        }
      } else {
        log("General error: $e");
        log("Stack trace: $stackTrace");
        showErrorSnack(Messages.authenticationFailure);
      }
    }
  }

  /// Get FCM token with retry logic
  Future<String?> _getFCMTokenWithRetry({int maxRetries = 3}) async {
    String? deviceToken;
    int retryCount = 0;

    while (deviceToken == null && retryCount < maxRetries) {
      try {
        deviceToken = await _firebaseService.getFCMToken();

        if (deviceToken == null) {
          retryCount++;
          log('⚠️ FCM token is null, retry $retryCount/$maxRetries');

          if (retryCount < maxRetries) {
            // Wait before retrying (exponential backoff)
            await Future.delayed(Duration(seconds: retryCount));
          }
        } else {
          log('✅ FCM token retrieved: ${deviceToken.substring(0, 20)}...');
          break;
        }
      } catch (e) {
        retryCount++;
        log('❌ Error getting FCM token (attempt $retryCount): $e');

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
    }

    if (deviceToken == null) {
      log('⚠️ Warning: Failed to get FCM token after $maxRetries attempts');
      log('⚠️ Proceeding with login without device token');
    }

    return deviceToken;
  }

  // Method to handle logout
  Future<void> logout() async {
    showCircle();

    try {
      log('═══════════════════════════════════════');
      log('STARTING LOGOUT PROCESS');
      log('═══════════════════════════════════════');

      // Get the current device token before clearing auth data
      String? deviceToken = await _firebaseService.getFCMToken();

      // Get user ID or other identifier
      String? userId =
          AuthRepo.customerId?.toString() ?? AuthRepo.driverId?.toString();

      // Get the auth token before clearing
      String? authToken = AuthRepo.token;

      log('User ID: $userId');
      log('Device Token: ${deviceToken?.substring(0, 20)}...');
      log('Auth Token: ${authToken?.substring(0, 20)}...');

      // Call logout API with authorization token
      final response = await restApi.logout(
        token: authToken != null ? 'Bearer $authToken' : null,
        id: userId,
        deviceToken: deviceToken,
      );

      log('✅ Logout API response: $response');

      // Delete FCM token locally
      try {
        await _firebaseService.deleteToken();
        log('✅ FCM token deleted successfully');
      } catch (tokenError) {
        log('⚠️ Warning: Error deleting FCM token: $tokenError');
        // Continue with logout even if token deletion fails
      }

      // Clear local auth data
      AuthRepo.logOut();
      log('✅ Local auth data cleared');

      removeCircle();
      showSuccessSnack('Logged out successfully');

      // Navigate to login screen
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

      log('✅ Logout completed successfully');
    } catch (e, stackTrace) {
      log('❌ Logout error: $e');
      log('Stack trace: $stackTrace');
      removeCircle();

      // Handle specific error cases
      if (e is DioException) {
        log("DioException during logout: ${e.message}");
        log("Status code: ${e.response?.statusCode}");

        // Check if it's a network error or server error
        if (e.response?.statusCode == 401) {
          // Token might be expired, still clear local data and navigate
          log('⚠️ Token expired or invalid, clearing local data anyway');
          await _performLocalLogout();
        } else if (e.response?.statusCode != null) {
          // Server responded with an error
          showErrorSnack('Logout failed. Please try again.');
        } else {
          // Network error - still logout locally
          log('⚠️ Network error during logout, performing local logout');
          await _performLocalLogout();
        }
      } else {
        log("General error during logout: $e");
        showErrorSnack('An error occurred during logout');
      }
    }
  }

  /// Helper method to perform local logout when API fails
  Future<void> _performLocalLogout() async {
    try {
      // Delete FCM token locally
      await _firebaseService.deleteToken();
      log('✅ FCM token deleted (local logout)');
    } catch (tokenError) {
      log('⚠️ Error deleting FCM token during local logout: $tokenError');
    }

    // Clear local auth data
    AuthRepo.logOut();
    log('✅ Local auth data cleared (local logout)');

    // Navigate to login screen
    NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);

    showSuccessSnack('Logged out locally');
  }

  /// Force logout - clears local data regardless of API response
  Future<void> forceLogout() async {
    showCircle();
    log('⚠️ FORCE LOGOUT INITIATED');

    try {
      // Attempt API call but don't wait for success
      String? deviceToken = await _firebaseService.getFCMToken();
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
            log('⚠️ Force logout: API call failed but continuing: $error');
          });
    } catch (e) {
      log('⚠️ Force logout: Error during API call: $e');
    }

    // Clear local data regardless of API response
    await _performLocalLogout();
    removeCircle();
    log('✅ Force logout completed');
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated {
    return AuthRepo.isAuthenticated;
  }

  /// Update device token (call this when token refreshes)
  Future<void> updateDeviceToken() async {
    try {
      if (!AuthRepo.isAuthenticated) {
        log('⚠️ Cannot update token: User not authenticated');
        return;
      }

      String? deviceToken = await _firebaseService.getFCMToken();

      if (deviceToken != null) {
        // TODO: Call API to update device token on server
        // await restApi.updateDeviceToken(deviceToken: deviceToken);
        log('✅ Device token updated: ${deviceToken.substring(0, 20)}...');
      } else {
        log('⚠️ Cannot update token: Token is null');
      }
    } catch (e) {
      log('❌ Error updating device token: $e');
    }
  }
}
