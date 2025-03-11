part of 'login_bloc.dart';

abstract class LoginEvent {}

class ButtonEnableEvent extends LoginEvent {
  final bool buttonEnabled;

  ButtonEnableEvent({required this.buttonEnabled});
}

class PwdVisibleEvent extends LoginEvent {
  final bool obsecureEnabled;
  final String? controllerCheck;
  PwdVisibleEvent({required this.obsecureEnabled, this.controllerCheck});
}
