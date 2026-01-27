import 'dart:convert';

import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../providers/login_controller.dart';
import '../util/shared_pref.dart';

class AuthRepo {
  static const _prefUserKey = "userBase";
  static const _prefLoginType = "loginType";
  static const _prefTokenKey = "token";
  static const _prefRoleKey = "role";
  static const _prefCustomerIdKey = "customerId";
  static const _prefDriverIdKey = "driverId";

  static const _prefLastEndMeterReadingKey = "lastEndMeterReading";
  static const _prefLastTripStopIdKey = "lastTripStopId";

  static set token(String? token) {
    if (token == null) {
      prefs?.remove(_prefTokenKey);
    } else {
      prefs?.setString(_prefTokenKey, token);
    }
  }

  static String? get token {
    return prefs?.getString(_prefTokenKey);
  }

  static set role(String? role) {
    if (role == null) {
      prefs?.remove(_prefRoleKey);
    } else {
      prefs?.setString(_prefRoleKey, role);
    }
  }

  static set lastEndMeterReading(String? reading) {
    if (reading == null) {
      prefs?.remove(_prefLastEndMeterReadingKey);
    } else {
      prefs?.setString(_prefLastEndMeterReadingKey, reading);
    }
  }

  static String? get lastEndMeterReading {
    return prefs?.getString(_prefLastEndMeterReadingKey);
  }

  static set lastTripStopId(int? stopId) {
    if (stopId == null) {
      prefs?.remove(_prefLastTripStopIdKey);
    } else {
      prefs?.setInt(_prefLastTripStopIdKey, stopId);
    }
  }

  static int? get lastTripStopId {
    return prefs?.getInt(_prefLastTripStopIdKey);
  }

  static String? get role {
    return prefs?.getString(_prefRoleKey);
  }

  static set user(String? user) {
    if (user == null) {
      prefs?.remove(_prefUserKey);
    } else {
      final userJson = jsonEncode(user);
      prefs?.setString(_prefUserKey, userJson);
    }
  }

  static String? get user {
    var value = prefs?.getString(_prefUserKey);
    if (value == null) return null;

    final userJson = jsonDecode(value);
    return userJson;
  }

  static set loginType(LoginType? loginType) {
    if (loginType == null) {
      prefs?.remove(_prefLoginType);
    } else {
      prefs?.setString(_prefLoginType, loginType.name);
    }
  }

  static LoginType? get loginType {
    final type = prefs?.getString(_prefLoginType);
    if (type == null) return null;

    return LoginType.values.firstWhere(
      (element) => element.name == type,
      orElse: () => LoginType.admin,
    );
  }

  static set customerId(int? customerId) {
    if (customerId == null) {
      prefs?.remove(_prefCustomerIdKey);
    } else {
      final userJson = jsonEncode(customerId);
      prefs?.setString(_prefCustomerIdKey, userJson);
    }
  }

  static int? get customerId {
    var value = prefs?.getString(_prefCustomerIdKey);
    if (value == null) return null;
    final customerIdJson = jsonDecode(value);
    return customerIdJson;
  }

  static set driverId(int? driverId) {
    if (driverId == null) {
      prefs?.remove(_prefDriverIdKey);
    } else {
      final userJson = jsonEncode(driverId);
      prefs?.setString(_prefDriverIdKey, userJson);
    }
  }

  static int? get driverId {
    var value = prefs?.getString(_prefDriverIdKey);
    if (value == null) return null;
    final driverIdJson = jsonDecode(value);
    return driverIdJson;
  }

  // Fixed logout method - clear individual keys instead of clearing all prefs
  static logOut() {
    // Clear all auth-related data individually
    token = null;
    role = null;
    user = null;
    loginType = null;
    customerId = null;
    lastEndMeterReading = null; // ADD THIS
    lastTripStopId = null;

    // Navigate to login screen
    NavigationService().pushNavigation(Screenroutes.login);
  }

  // Helper method to check if user is authenticated
  static bool get isAuthenticated {
    return token != null && token!.isNotEmpty;
  }

  // Helper method to clear all auth data (alternative to logOut if you want to keep navigation separate)
  static void clearAuthData() {
    token = null;
    role = null;
    user = null;
    loginType = null;
    customerId = null;
    lastEndMeterReading = null; // ADD THIS
    lastTripStopId = null;
  }
}
