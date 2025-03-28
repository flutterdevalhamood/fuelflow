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
    print('login');
    print('email $email');
    print('password $password');

    showCircle();

    try {
      print('try');
      final loginResponse = await restApi.login(
        email: email,
        password: password,
      );

      if (loginResponse.IsSuccess == true) {
        log(JsonEncoder.withIndent("\t").convert(loginResponse));

        final data = loginResponse.Data;
        AuthRepo.loginType = loginType;
        AuthRepo.token = loginResponse.Token;
        AuthRepo.role = loginResponse.Data?.roles?.Name;
        AuthRepo.user = loginResponse.Data?.name;
        AuthRepo.customerId = loginResponse.Data?.customer?.id;
        print('customeriddddd ${AuthRepo.customerId}');

        NavigationService().pushNavigation(
          Screenroutes.dashboard,
          arguments: {'role': loginResponse.Data?.roles?.Name},
        );
      } else {
        showErrorSnack(Messages.authenticationFailure);
      }
    } catch (e) {
      if (e is TypeError) {
        if (e is DioException) {
          log("TypeError", stackTrace: e.stackTrace);
        }
        log("TypeError", stackTrace: e.stackTrace);
      }
      showErrorSnack(Messages.authenticationFailure);
    }

    removeCircle();
  }
}
