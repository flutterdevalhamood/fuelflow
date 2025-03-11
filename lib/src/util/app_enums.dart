enum ApiRequestStatus {
  initial,
  success,
  error,
  loading,
  validationSuccess,
  validationFailed,
}

extension ApiRequestStatusX on ApiRequestStatus {
  bool get isInitial => this == ApiRequestStatus.initial;

  bool get isSuccess => this == ApiRequestStatus.success;

  bool get isError => this == ApiRequestStatus.error;

  bool get isLoading => this == ApiRequestStatus.loading;

  bool get isValidationSuccess => this == ApiRequestStatus.validationSuccess;

  bool get isValidationFailed => this == ApiRequestStatus.validationFailed;
}

enum ElevatedButtonState { active, disable }

enum AppBarType { backWithTitle, backWithAction, empty }
