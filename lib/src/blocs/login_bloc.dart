import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/src/util/app_enums.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginEvent>((event, emit) {});
    on<ButtonEnableEvent>((event, emit) {
      emit(ButtonEnableState(buttonEnabled: event.buttonEnabled));
    });
    on<PwdVisibleEvent>((event, emit) {
      emit(
        PwdVisibleState(
          obsecureEnabled: event.obsecureEnabled,
          controllerCheck: event.controllerCheck,
        ),
      );
    });
  }
}
