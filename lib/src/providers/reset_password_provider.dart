import 'package:flutter/material.dart';

class ResetPasswordProvider extends ChangeNotifier {
  SendStatus _status = SendStatus.initialize;
  VerifyStatus _verifyStatus = VerifyStatus.initialize;
  String? token;

  String _message = '';

  SendStatus get status => _status;

  VerifyStatus get verifyStatus => _verifyStatus;

  String get message => _message;
  String _email = '';

  String get email => _email;

  // void sendotp(String data) async {
  //   if (_status == SendStatus.loading) return;
  //   try {
  //     // verifyNotifyState(VerifyStatus.initialize);
  //     notifyState(SendStatus.loading);
  //     await AppRepository().sendOTP(data) ?? false;
  //     _email = data;
  //     notifyState(SendStatus.success);
  //   } catch (e) {
  //     _message = e.toString().replaceAll('Exception:', '');
  //     notifyState(SendStatus.failed);
  //   }
  // }
  //
  // void verifyotp(Map<String, dynamic> data) async {
  //   if (_verifyStatus == VerifyStatus.loading) return;
  //   try {
  //     // notifyState(SendStatus.initialize);
  //     // verifyNotifyState(VerifyStatus.loading);
  //     data.addAll({'email': _email});
  //     final res = (await AppRepository().verifyOTP(data)) ?? false;
  //     if (res['success'] == true) {
  //       token = res['data']["token"];
  //       log(token ?? '', name: "token Pasw");
  //       final ctx = navigatorKey!.currentState!.context;
  //       if (ctx.mounted) {
  //         // verifyNotifyState(VerifyStatus.success);
  //         Navigator.pushNamed(ctx, AppRoutes.changePassword,
  //             arguments: {"email": email, "token": token});
  //       }
  //     }
  //   } catch (e) {
  //     _message = e.toString().replaceAll('Exception:', '');
  //     // verifyNotifyState(VerifyStatus.failed);
  //     final ctx = navigatorKey!.currentState!.context;
  //     if (ctx.mounted) {
  //       customSnackBar(ctx, message: _message, type: SnackBarType.error);
  //     }
  //   }
  // }

  void notifyState(SendStatus status) {
    _status = status;
    notifyListeners();
  }

  void verifyNotifyState(VerifyStatus status) {
    _verifyStatus = status;
    notifyListeners();
  }
}

enum SendStatus { initialize, loading, success, failed }

enum VerifyStatus { initialize, loading, success, failed }
