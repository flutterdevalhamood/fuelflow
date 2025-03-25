import 'package:flutter/services.dart';

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Always maintain the +971 prefix
    if (!newValue.text.startsWith('+971')) {
      return TextEditingValue(
        text: '+971',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // Prevent deletion of the prefix
    if (newValue.text.length < 4) {
      return TextEditingValue(
        text: '+971',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    return newValue;
  }
}
