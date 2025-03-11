part of 'login_bloc.dart';

abstract class LoginState {
  ApiRequestStatus status;
  String? errorMessage;
  int? errorCode, resendOtpElepsedSeconds;
  bool obsecureEnabled;
  bool buttonEnabled;
  String? controllerCheck;

  LoginState({
    this.status = ApiRequestStatus.initial,
    this.errorMessage,
    this.errorCode,
    this.resendOtpElepsedSeconds,
    this.obsecureEnabled = true,
    this.buttonEnabled = false,
    this.controllerCheck,
  });
}

final class LoginInitial extends LoginState {}

class ButtonEnableState extends LoginState {
  // final bool buttonEnabled;

  ButtonEnableState({super.buttonEnabled});
}

class PwdVisibleState extends LoginState {
  PwdVisibleState({super.obsecureEnabled, super.controllerCheck});
}
