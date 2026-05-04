import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class DocumentsFormState {
  // 1. Controladores
  final cpf = TextEditingController();
  final nis = TextEditingController();
  final cnsNumber = TextEditingController();
  final rgNumber = TextEditingController();
  final rgAgency = TextEditingController();
  final rgDate = TextEditingController();
  final birthDate = TextEditingController();
  final rgUf = ValueNotifier<String?>(null);

  // 2. Helpers — RG é totalmente opcional/livre (sem validação grupal).

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
    if (digits.isEmpty) return ReferencePersonLn10.errorRequired;
    if (digits.length != 11) return ReferencePersonLn10.cpfError;
    return null;
  }

  String? get nisError {
    final digits = nis.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 11) return ReferencePersonLn10.nisError;
    return null;
  }

  String? get cnsError {
    final digits = cnsNumber.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 15) return ReferencePersonLn10.cnsError;
    final firstDigit = digits[0];
    if (!{'1', '2', '7', '8', '9'}.contains(firstDigit)) {
      return ReferencePersonLn10.errorCnsFirstDigit;
    }
    return null;
  }

  // RG totalmente livre: sem validação em nenhum dos 4 campos.
  String? get rgNumberError => null;
  String? get rgUfError => null;
  String? get rgAgencyError => null;
  String? get rgDateError => null;

  String? get birthDateError {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return ReferencePersonLn10.birthDateError;
    if (digits.length != 8) return ReferencePersonLn10.errorDateIncomplete;
    final parsed = _parseDateBr(digits);
    if (parsed == null) return ReferencePersonLn10.errorDateInvalid;
    if (parsed.isAfter(DateTime.now())) {
      return ReferencePersonLn10.birthDateFutureError;
    }
    return null;
  }

  // 5. Validação do Step (RG fora — campos livres)
  bool get isValidForNextStep {
    if (birthDateError != null) return false;
    if (cpfError != null) return false;
    if (nisError != null) return false;
    if (cnsError != null) return false;
    return true;
  }

  List<String> get validationErrors => [
    ?cpfError,
    ?nisError,
    ?cnsError,
    ?birthDateError,
  ];

  // 6. Acesso a valores parseados
  DateTime? get birthDateParsed =>
      _parseDateBr(birthDate.text.replaceAll(RegExp(r'\D'), ''));

  DateTime? get rgDateParsed =>
      _parseDateBr(rgDate.text.replaceAll(RegExp(r'\D'), ''));

  String get cpfDigits => cpf.text.replaceAll(RegExp(r'\D'), '');
  String get nisDigits => nis.text.replaceAll(RegExp(r'\D'), '');
  String get cnsDigits => cnsNumber.text.replaceAll(RegExp(r'\D'), '');

  // 7. Gerenciamento de Memória
  void dispose() {
    cpf.dispose();
    nis.dispose();
    cnsNumber.dispose();
    rgNumber.dispose();
    rgAgency.dispose();
    rgDate.dispose();
    birthDate.dispose();
    rgUf.dispose();
  }
}
