import 'package:flutter/services.dart';

bool _isDigit(String char) {
  final code = char.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39; // '0'-'9'
}

bool _isAlphaNumeric(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 0x30 && code <= 0x39) || // 0-9
      (code >= 0x41 && code <= 0x5A) || // A-Z
      (code >= 0x61 && code <= 0x7A); // a-z
}

/// A [TextInputFormatter] that applies a mask pattern to input text.
///
/// Uses `#` as digit placeholder and any other character as literal.
/// Example: mask '###.###.###-##' formats '12345678901' as '123.456.789-01'.
///
/// Expects pre-filtered input (use with [FilteringTextInputFormatter] or
/// [LengthLimitingTextInputFormatter] in the formatters list).
class _MaskFormatter extends TextInputFormatter {
  final String mask;
  final bool Function(String) _charTest;
  final int _maxRawChars;

  _MaskFormatter({required this.mask, required bool Function(String) charTest})
      : _charTest = charTest,
        _maxRawChars = '#'.allMatches(mask).length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();
    var rawCount = 0;
    var textIndex = 0;

    for (var maskIndex = 0;
        maskIndex < mask.length && rawCount < _maxRawChars;
        maskIndex++) {
      if (mask[maskIndex] == '#') {
        // Advance through input until we find a valid char or exhaust input.
        while (textIndex < text.length) {
          final char = text[textIndex];
          textIndex++;
          if (_charTest(char)) {
            buffer.write(char);
            rawCount++;
            break;
          }
        }
        // No more valid input chars — stop.
        if (rawCount == 0 || buffer.length == 0) {
          if (textIndex >= text.length && rawCount < maskIndex + 1) break;
        }
        if (textIndex > text.length) break;
      } else {
        // Only write literal if there's still raw input ahead.
        if (textIndex < text.length || rawCount > 0) {
          buffer.write(mask[maskIndex]);
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Standard input masks for ACDG system.
///
/// Each field returns a `List<TextInputFormatter>` combining native Flutter
/// filters (keyboard-level restriction + length limit) with mask formatting.
///
/// Usage: `inputFormatters: AppMasks.cpf` (already a list, no wrapping needed).
abstract final class AppMasks {
  /// CPF: 11 digits → ###.###.###-##
  static final List<TextInputFormatter> cpf = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(14),
    _MaskFormatter(mask: '###.###.###-##', charTest: _isDigit),
  ];

  /// CEP: 8 digits → #####-###
  static final List<TextInputFormatter> cep = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
    _MaskFormatter(mask: '#####-###', charTest: _isDigit),
  ];

  /// Date: 8 digits → ## / ## / ####
  static final List<TextInputFormatter> date = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(14),
    _MaskFormatter(mask: '## / ## / ####', charTest: _isDigit),
  ];

  /// Phone: 11 digits → (##) #####-####
  static final List<TextInputFormatter> phone = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(15),
    _MaskFormatter(mask: '(##) #####-####', charTest: _isDigit),
  ];

  /// RG: up to 9 alphanumeric chars → ##.###.###-#
  static final List<TextInputFormatter> rg = [
    LengthLimitingTextInputFormatter(12),
    _MaskFormatter(mask: '##.###.###-#', charTest: _isAlphaNumeric),
  ];
}
