import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atoms/acdg_text.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

// ─── Character Predicates ─────────────────────────────────────────

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

bool _isAlphaNumeric(int unit) =>
    _isDigit(unit) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A);

// ─── Pure Transformations ─────────────────────────────────────────

String _extractRaw(String text, bool Function(int) predicate) =>
    String.fromCharCodes(text.codeUnits.where(predicate));

String _applyMask(String raw, String mask) {
  final buffer = StringBuffer();
  var rawIndex = 0;
  for (var i = 0; i < mask.length && rawIndex < raw.length; i++) {
    if (mask.codeUnitAt(i) == 0x23) {
      buffer.write(raw[rawIndex++]);
    } else {
      buffer.writeCharCode(mask.codeUnitAt(i));
    }
  }
  return buffer.toString();
}

// ─── Validators ───────────────────────────────────────────────────

typedef FieldValidator = String? Function(String raw);

String? _validateCpf(String raw) => switch (raw.length) {
  0 => null,
  11 => null,
  _ => 'CPF deve conter 11 dígitos',
};

String? _validateCep(String raw) => switch (raw.length) {
  0 => null,
  8 => null,
  _ => 'CEP deve conter 8 dígitos',
};

String? _validateDate(String raw) {
  if (raw.isEmpty) return null;
  if (raw.length < 8) return 'Data incompleta';
  final day = int.parse(raw.substring(0, 2));
  final month = int.parse(raw.substring(2, 4));
  if (month < 1 || month > 12) return 'Mês inválido (01–12)';
  if (day < 1 || day > 31) return 'Dia inválido (01–31)';
  return null;
}

String? _validatePhone(String raw) => switch (raw.length) {
  0 => null,
  10 || 11 => null,
  _ => 'Telefone deve conter 10 ou 11 dígitos',
};

String? _validateRg(String raw) {
  if (raw.isEmpty) return null;
  if (raw.length < 5) return 'RG incompleto';
  return null;
}

// ─── Field Configuration ──────────────────────────────────────────

enum MaskedFieldVariant { cpf, cep, date, phone, rg }

class _FieldConfig {
  final String mask;
  final String defaultPlaceholder;
  final TextInputType keyboardType;
  final bool Function(int) charPredicate;
  final FieldValidator validate;
  final List<TextInputFormatter> nativeFormatters;

  const _FieldConfig({
    required this.mask,
    required this.defaultPlaceholder,
    required this.keyboardType,
    required this.charPredicate,
    required this.validate,
    required this.nativeFormatters,
  });

  int get maxRawLength => mask.codeUnits.where((u) => u == 0x23).length;

  String extractRaw(String text) => _extractRaw(text, charPredicate);
  String format(String raw) => _applyMask(raw, mask);

  static final _registry = <MaskedFieldVariant, _FieldConfig>{
    MaskedFieldVariant.cpf: _FieldConfig(
      mask: '###.###.###-##',
      defaultPlaceholder: '000.000.000-00',
      keyboardType: TextInputType.number,
      charPredicate: _isDigit,
      validate: _validateCpf,
      nativeFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    MaskedFieldVariant.cep: _FieldConfig(
      mask: '#####-###',
      defaultPlaceholder: '00000-000',
      keyboardType: TextInputType.number,
      charPredicate: _isDigit,
      validate: _validateCep,
      nativeFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    MaskedFieldVariant.date: _FieldConfig(
      mask: '## / ## / ####',
      defaultPlaceholder: 'DD / MM / AAAA',
      keyboardType: TextInputType.number,
      charPredicate: _isDigit,
      validate: _validateDate,
      nativeFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    MaskedFieldVariant.phone: _FieldConfig(
      mask: '(##) #####-####',
      defaultPlaceholder: '(00) 00000-0000',
      keyboardType: TextInputType.phone,
      charPredicate: _isDigit,
      validate: _validatePhone,
      nativeFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    MaskedFieldVariant.rg: const _FieldConfig(
      mask: '##.###.###-#',
      defaultPlaceholder: '00.000.000-0',
      keyboardType: TextInputType.text,
      charPredicate: _isAlphaNumeric,
      validate: _validateRg,
      nativeFormatters: [],
    ),
  };

  static _FieldConfig of(MaskedFieldVariant variant) => _registry[variant]!;
}

// ─── Date Helpers (BR format: DDMMYYYY) ──────────────────────────

/// Parses a raw "DDMMYYYY" string into [DateTime], or null if invalid.
DateTime? dateBrParse(String raw) {
  if (raw.length != 8) return null;
  final day = int.tryParse(raw.substring(0, 2));
  final month = int.tryParse(raw.substring(2, 4));
  final year = int.tryParse(raw.substring(4, 8));
  if (day == null || month == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

/// Formats a [DateTime] into raw "DDMMYYYY" for [AcdgMaskedField.date].
String dateBrFormat(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.year}';

// ─── Widget ───────────────────────────────────────────────────────

/// A self-contained masked input field with built-in formatting,
/// validation, and ViewModel error support.
///
/// Uses [TextEditingController] internally to manage mask formatting
/// via listener. Native [FilteringTextInputFormatter] handles
/// keyboard-level filtering. Validation runs on blur.
///
/// Emits **raw** (unmasked) values via [onChanged].
///
/// ```dart
/// AcdgMaskedField.cpf(
///   label: 'CPF',
///   initialValue: data.cpf,
///   errorText: errors['cpf'],
///   onChanged: (raw) => vm.update(cpf: raw),
/// )
/// ```
class AcdgMaskedField extends StatefulWidget {
  final MaskedFieldVariant variant;
  final String label;
  final String? placeholder;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool inverted;

  const AcdgMaskedField.cpf({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.inverted = false,
  }) : variant = MaskedFieldVariant.cpf;

  const AcdgMaskedField.cep({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.inverted = false,
  }) : variant = MaskedFieldVariant.cep;

  const AcdgMaskedField.date({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.inverted = false,
  }) : variant = MaskedFieldVariant.date;

  const AcdgMaskedField.phone({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.inverted = false,
  }) : variant = MaskedFieldVariant.phone;

  const AcdgMaskedField.rg({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.inverted = false,
  }) : variant = MaskedFieldVariant.rg;

  @override
  State<AcdgMaskedField> createState() => _AcdgMaskedFieldState();
}

class _AcdgMaskedFieldState extends State<AcdgMaskedField> {
  late final _FieldConfig _config;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _rawValue = '';
  bool _touched = false;

  // ─── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _config = _FieldConfig.of(widget.variant);
    _rawValue = widget.initialValue ?? '';
    _controller = TextEditingController(
      text: _rawValue.isNotEmpty ? _config.format(_rawValue) : '',
    );
    _controller.addListener(_onControllerChanged);
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AcdgMaskedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final incoming = widget.initialValue ?? '';
      if (incoming != _rawValue) {
        _rawValue = incoming;
        _controller
          ..removeListener(_onControllerChanged)
          ..text = incoming.isNotEmpty ? _config.format(incoming) : ''
          ..addListener(_onControllerChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  // ─── Observers ────────────────────────────────────────────────

  void _onControllerChanged() {
    final currentText = _controller.text;
    final extracted = _config.extractRaw(currentText);
    final limited = extracted.length > _config.maxRawLength
        ? extracted.substring(0, _config.maxRawLength)
        : extracted;
    final formatted = _config.format(limited);

    if (formatted == currentText && limited == _rawValue) return;

    final rawChanged = limited != _rawValue;
    _rawValue = limited;

    if (formatted != currentText) {
      _controller
        ..removeListener(_onControllerChanged)
        ..value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        )
        ..addListener(_onControllerChanged);
    }

    if (rawChanged) {
      widget.onChanged?.call(limited);
      if (_touched) setState(() {});
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && !_touched) {
      setState(() => _touched = true);
    }
  }

  // ─── Error Resolution ─────────────────────────────────────────

  String? get _effectiveError {
    if (widget.errorText != null) return widget.errorText;
    if (!_touched) return null;
    return _config.validate(_rawValue);
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final error = _effectiveError;
    final hasError = error != null;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AcdgText(
              widget.label,
              variant: AcdgTextVariant.headingMedium,
              color: widget.inverted
                  ? AppColors.textOnDark
                  : AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: hasError ? AppColors.danger : AppColors.inputLine,
                    width: hasError ? 2.0 : 1.0,
                  ),
                ),
              ),
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: _config.keyboardType,
                inputFormatters: _config.nativeFormatters,
                readOnly: widget.readOnly,
                style: AppTypography.bodyLarge(screenWidth)
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      widget.placeholder ?? _config.defaultPlaceholder,
                  hintStyle: AppTypography.inputPlaceholder(screenWidth)
                      .copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(
                error,
                style: AppTypography.caption(screenWidth).copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
