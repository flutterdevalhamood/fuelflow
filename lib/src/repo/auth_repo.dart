import 'dart:convert';

import 'package:sample/src/util/app_routes.dart';

import '../BaseScreen.dart';
import '../providers/login_controller.dart';
import '../util/shared_pref.dart';

class AuthRepo {
  static const _prefUserKey = "userBase";
  static const _prefLoginType = "loginType";
  static const _prefTokenKey = "token";

  static set token(String? token) {
    if (token == null) {
      prefs?.remove(_prefTokenKey);
    } else {
      prefs?.setString(_prefTokenKey, token);
    }
  }

  static String? get token {
    return prefs?.getString(_prefTokenKey); // Retrieve token
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

    return LoginType.values.firstWhere(
      (element) => element.name == type,
      orElse: () => LoginType.admin,
    );
  }

  static logOut() {
    prefs?.clear();
    loginType = null;
    user = null;
    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      Screenroutes.login,
      (route) => false,
    );
  }
}
