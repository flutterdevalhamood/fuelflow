import 'package:flutter/services.dart';

class QuantityInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle empty input
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow only one decimal point
    if (newValue.text.split('.').length > 2) {
      return oldValue;
    }

    // Split into whole and decimal parts
    final parts = newValue.text.split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Restrict to 4 digits before decimal
    if (wholePart.length > 4) {
      return oldValue;
    }

    // Restrict to 2 digits after decimal
    if (decimalPart.length > 2) {
      return oldValue;
    }

    return newValue;
  }
}
