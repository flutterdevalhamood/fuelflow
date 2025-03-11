import 'package:flutter/services.dart';
import 'package:form_field_validator/form_field_validator.dart';

class InputValidator {
  static List<TextInputFormatter> userIdValidator({int maxLength = 100}) {
    return <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9@!?._]+$')),
      FilteringTextInputFormatter.deny(InputValidator.denyEmojis),
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  static List<TextInputFormatter> passwordValidator() {
    return <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9!@#^&*()_;:-]')),
      FilteringTextInputFormatter.deny(InputValidator.denyEmojis),
    ];
  }

  static RegExp denyEmojis = RegExp(
    '(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );

  static RequiredValidator requiredValidator([
    String errorText = 'Required field',
  ]) {
    return RequiredValidator(errorText: errorText);
  }

  static final emailValidator = EmailValidator(
    errorText: 'Please enter a valid email',
  );
}
