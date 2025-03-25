import 'package:flutter/services.dart';

class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty input
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Basic email pattern validation while typing
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]*@?[a-zA-Z0-9-]*\.?[a-zA-Z0-9-]*$',
    );

    if (!emailRegex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Prevent multiple @ symbols
    if ('@'.allMatches(newValue.text).length > 1) {
      return oldValue;
    }

    // Prevent dots at the beginning or end of local part
    if (newValue.text.contains('@')) {
      final parts = newValue.text.split('@');
      if (parts[0].startsWith('.') || parts[0].endsWith('.')) {
        return oldValue;
      }
    }

    return newValue;
  }
}
