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
    try {
      // Delete FCM token on logout
      await FirebaseService().deleteToken();

      // You might want to call a logout API here to remove device token from server
      // await restApi.logout(deviceToken: FirebaseService().fcmToken);

      AuthRepo.logOut();
      showSuccessSnack('Logged out successfully');
    } catch (e) {
      log('Logout error: $e');
      // Even if logout API fails, clear local data
      AuthRepo.logOut();
    }
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
