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
  static const _prefDeviceTokenKey = "deviceToken"; // ADD THIS

  static const _prefLastEndMeterReadingKey = "lastEndMeterReading";
  static const _prefLastTripStopIdKey = "lastTripStopId";
  static const _prefLastAvailableQtyKey = "lastAvailableQty";

  static const _prefCustomerNameKey = "customerName";
  static const _prefCustomerEmailKey = "customerEmail";
  static const _prefCustomerMobileKey = "customerMobile";
  static const _prefCustomerRepresentativeKey = "customerRepresentative";
  static const _prefCustomerSecondaryMobileKey = "customerSecondaryMobile";

  static String? lastEndMeterPhotoPath;

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

  static String? get role {
    return prefs?.getString(_prefRoleKey);
  }

  // ADD THIS - Device token getter and setter
  static set deviceToken(String? token) {
    if (token == null) {
      prefs?.remove(_prefDeviceTokenKey);
    } else {
      prefs?.setString(_prefDeviceTokenKey, token);
    }
  }

  static String? get deviceToken {
    return prefs?.getString(_prefDeviceTokenKey);
  }

  static String? get customerName {
    return prefs?.getString(_prefCustomerNameKey);
  }

  static set customerName(String? name) {
    if (name == null) {
      prefs?.remove(_prefCustomerNameKey);
    } else {
      prefs?.setString(_prefCustomerNameKey, name);
    }
  }

  static String? get customerEmail {
    return prefs?.getString(_prefCustomerEmailKey);
  }

  static set customerEmail(String? email) {
    if (email == null) {
      prefs?.remove(_prefCustomerEmailKey);
    } else {
      prefs?.setString(_prefCustomerEmailKey, email);
    }
  }

  static String? get customerMobile {
    return prefs?.getString(_prefCustomerMobileKey);
  }

  static set customerMobile(String? mobile) {
    if (mobile == null) {
      prefs?.remove(_prefCustomerMobileKey);
    } else {
      prefs?.setString(_prefCustomerMobileKey, mobile);
    }
  }

  static String? get customerRepresentative {
    return prefs?.getString(_prefCustomerRepresentativeKey);
  }

  static set customerRepresentative(String? representative) {
    if (representative == null) {
      prefs?.remove(_prefCustomerRepresentativeKey);
    } else {
      prefs?.setString(_prefCustomerRepresentativeKey, representative);
    }
  }

  static String? get customerSecondaryMobile {
    return prefs?.getString(_prefCustomerSecondaryMobileKey);
  }

  static set customerSecondaryMobile(String? secondaryMobile) {
    if (secondaryMobile == null) {
      prefs?.remove(_prefCustomerSecondaryMobileKey);
    } else {
      prefs?.setString(_prefCustomerSecondaryMobileKey, secondaryMobile);
    }
  }

  // Method to save all customer data at once
  static void setCustomerData({
    String? name,
    String? email,
    String? mobile,
    String? representative,
    String? secondaryMobile,
  }) {
    customerName = name;
    customerEmail = email;
    customerMobile = mobile;
    customerRepresentative = representative;
    customerSecondaryMobile = secondaryMobile;
  }

  // Method to clear all customer data
  static void clearCustomerData() {
    customerName = null;
    customerEmail = null;
    customerMobile = null;
    customerRepresentative = null;
    customerSecondaryMobile = null;
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

  static set lastAvailableQty(double? qty) {
    if (qty == null) {
      prefs?.remove(_prefLastAvailableQtyKey);
    } else {
      prefs?.setDouble(_prefLastAvailableQtyKey, qty);
    }
  }

  static double? get lastAvailableQty {
    return prefs?.getDouble(_prefLastAvailableQtyKey);
  }

  // Fixed logout method - clear individual keys instead of clearing all prefs
  static logOut() {
    // Clear all auth-related data individually
    token = null;
    role = null;
    user = null;
    loginType = null;
    customerId = null;
    driverId = null;
    deviceToken = null; // ADD THIS
    lastEndMeterReading = null;
    lastTripStopId = null;
    lastAvailableQty = null;
    lastEndMeterPhotoPath = null;

    // Navigate to login screen
    NavigationService().pushNavigation(Screenroutes.login);
  }

  // Helper method to check if user is authenticated
  static bool get isAuthenticated {
    return token != null && token!.isNotEmpty;
  }

  // Helper method to clear all auth data
  static void clearAuthData() {
    token = null;
    role = null;
    user = null;
    loginType = null;
    customerId = null;
    driverId = null;
    deviceToken = null; // ADD THIS
    lastEndMeterReading = null;
    lastTripStopId = null;
    lastAvailableQty = null;
    lastEndMeterPhotoPath = null;
  }
}
