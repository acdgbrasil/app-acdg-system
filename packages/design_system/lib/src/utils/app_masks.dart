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
    // 1. Extract only valid raw characters from input
    final rawChars = StringBuffer();
    for (
      var i = 0;
      i < newValue.text.length && rawChars.length < _maxRawChars;
      i++
    ) {
      if (_charTest(newValue.text[i])) {
        rawChars.write(newValue.text[i]);
      }
    }

    final raw = rawChars.toString();
    if (raw.isEmpty) {
      return const TextEditingValue();
    }

    // 2. Apply mask over raw characters
    final buffer = StringBuffer();
    var rawIndex = 0;

    for (
      var maskIndex = 0;
      maskIndex < mask.length && rawIndex < raw.length;
      maskIndex++
    ) {
      if (mask[maskIndex] == '#') {
        buffer.write(raw[rawIndex]);
        rawIndex++;
      } else {
        buffer.write(mask[maskIndex]);
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

  /// CNS (Cartão Nacional de Saúde): 15 digits → ### #### #### ####
  static final List<TextInputFormatter> cns = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(18),
    _MaskFormatter(mask: '### #### #### ####', charTest: _isDigit),
  ];

  /// RG: up to 9 alphanumeric chars → ##.###.###-#
  static final List<TextInputFormatter> rg = [
    LengthLimitingTextInputFormatter(12),
    _MaskFormatter(mask: '##.###.###-#', charTest: _isAlphaNumeric),
  ];
}
