import 'package:flutter/widgets.dart';

class DocumentsFormState {
  // 1. Controladores
  final cpf = TextEditingController();
  final nis = TextEditingController();
  final rgNumber = TextEditingController();
  final rgAgency = TextEditingController();
  final rgDate = TextEditingController();
  final birthDate = TextEditingController();
  final rgUf = ValueNotifier<String?>(null);

  // 2. Helpers — grupo RG condicional
  bool get _hasAnyRgField =>
      rgNumber.text.trim().isNotEmpty ||
      rgUf.value != null ||
      rgAgency.text.trim().isNotEmpty ||
      rgDate.text.replaceAll(RegExp(r'\D'), '').isNotEmpty;

  bool get _allRgFieldsFilled =>
      rgNumber.text.trim().isNotEmpty &&
      rgUf.value != null &&
      rgAgency.text.trim().isNotEmpty &&
      rgDate.text.replaceAll(RegExp(r'\D'), '').length == 8;

  // 3. Helpers — parse de data BR (DDMMAAAA ou DD / MM / AAAA)
  DateTime? _parseDateBr(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  // 4. Getters de Erro
  String? get cpfError {
    final digits = cpf.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'CPF obrigatório';
    if (digits.length != 11) return 'CPF inválido';
    return null;
  }

  String? get nisError {
    final digits = nis.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 11) return 'NIS deve ter 11 dígitos';
    return null;
  }

  String? get rgNumberError {
    if (!_hasAnyRgField) return null;
    if (rgNumber.text.trim().isEmpty) return 'Preencha todos os campos do RG';
    return null;
  }

  String? get rgUfError {
    if (!_hasAnyRgField) return null;
    if (rgUf.value == null) return 'Preencha todos os campos do RG';
    return null;
  }

  String? get rgAgencyError {
    if (!_hasAnyRgField) return null;
    if (rgAgency.text.trim().isEmpty) return 'Preencha todos os campos do RG';
    return null;
  }

  String? get rgDateError {
    if (!_hasAnyRgField) return null;
    final digits = rgDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Preencha todos os campos do RG';
    if (digits.length != 8) return 'Data incompleta';
    if (_parseDateBr(digits) == null) return 'Data inválida';
    return null;
  }

  String? get birthDateError {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe a data de nascimento';
    if (digits.length != 8) return 'Data incompleta';
    final parsed = _parseDateBr(digits);
    if (parsed == null) return 'Data inválida';
    if (parsed.isAfter(DateTime.now())) return 'Data deve ser no passado';
    return null;
  }

  // 5. Validação do Step
  bool get isValidForNextStep {
    if (birthDateError != null) return false;
    if (cpfError != null) return false;
    if (nisError != null) return false;
    if (_hasAnyRgField && !_allRgFieldsFilled) return false;
    if (rgDateError != null) return false;
    return true;
  }

  List<String> get validationErrors => [
    if (cpfError != null) cpfError!,
    if (nisError != null) nisError!,
    if (rgNumberError != null) rgNumberError!,
    if (rgUfError != null) rgUfError!,
    if (rgAgencyError != null) rgAgencyError!,
    if (rgDateError != null) rgDateError!,
    if (birthDateError != null) birthDateError!,
  ];

  // 6. Acesso a valores parseados
  DateTime? get birthDateParsed =>
      _parseDateBr(birthDate.text.replaceAll(RegExp(r'\D'), ''));

  DateTime? get rgDateParsed =>
      _parseDateBr(rgDate.text.replaceAll(RegExp(r'\D'), ''));

  String get cpfDigits => cpf.text.replaceAll(RegExp(r'\D'), '');
  String get nisDigits => nis.text.replaceAll(RegExp(r'\D'), '');

  // 7. Gerenciamento de Memória
  void dispose() {
    cpf.dispose();
    nis.dispose();
    rgNumber.dispose();
    rgAgency.dispose();
    rgDate.dispose();
    birthDate.dispose();
    rgUf.dispose();
  }
}
