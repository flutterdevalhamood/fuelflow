import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

      final loginResponse = await restApi.login(
        email: email,
        password: password,
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
      // You might want to call a logout API here if your backend requires it
      // await restApi.logout();

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
}
