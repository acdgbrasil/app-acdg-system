import 'package:flutter/widgets.dart';

class DiagnosisEntryState {
  final icdCode = TextEditingController();
  final date = TextEditingController();
  final description = TextEditingController();

  // Helpers
  bool get isNotEmpty =>
      icdCode.text.trim().isNotEmpty ||
      date.text.replaceAll(RegExp(r'\D'), '').isNotEmpty ||
      description.text.trim().isNotEmpty;

  bool get isComplete =>
      icdCode.text.trim().isNotEmpty &&
      date.text.replaceAll(RegExp(r'\D'), '').length == 8 &&
      _parseDateBr(date.text) != null &&
      description.text.trim().isNotEmpty;

  // Getters de Erro
  String? get icdCodeError {
    if (!isNotEmpty) return null;
    if (icdCode.text.trim().isEmpty) return 'Informe o código CID';
    return null;
  }

  String? get dateError {
    if (!isNotEmpty) return null;
    final digits = date.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe a data do diagnóstico';
    if (digits.length != 8) return 'Data incompleta';
    if (_parseDateBr(date.text) == null) return 'Data inválida';
    return null;
  }

  String? get descriptionError {
    if (!isNotEmpty) return null;
    if (description.text.trim().isEmpty) return 'Informe a descrição';
    return null;
  }

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

  DateTime? get dateParsed => _parseDateBr(date.text);

  void dispose() {
    icdCode.dispose();
    date.dispose();
    description.dispose();
  }
}

class DiagnosesFormState {
  DiagnosesFormState() {
    _entries.value = [DiagnosisEntryState()];
  }

  final _entries = ValueNotifier<List<DiagnosisEntryState>>([]);

  ValueNotifier<List<DiagnosisEntryState>> get entries => _entries;

  void addEntry() {
    _entries.value = [..._entries.value, DiagnosisEntryState()];
  }

  void removeEntry(int index) {
    if (index <= 0 || index >= _entries.value.length) return;
    final removed = _entries.value[index];
    _entries.value = [
      for (var i = 0; i < _entries.value.length; i++)
        if (i != index) _entries.value[i],
    ];
    removed.dispose();
  }

  // Validação: pelo menos 1 completo, nenhum parcial incompleto
  bool get isValidForNextStep {
    final list = _entries.value;
    if (list.isEmpty) return false;
    final hasOneComplete = list.any((e) => e.isComplete);
    final hasIncomplete = list.any((e) => e.isNotEmpty && !e.isComplete);
    return hasOneComplete && !hasIncomplete;
  }

  List<String> get validationErrors {
    final list = _entries.value;
    final errors = <String>[];
    if (!list.any((e) => e.isComplete)) {
      errors.add('Adicione pelo menos um diagnóstico');
    }
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (e.icdCodeError != null) errors.add('Diagnóstico ${i + 1}: ${e.icdCodeError}');
      if (e.dateError != null) errors.add('Diagnóstico ${i + 1}: ${e.dateError}');
      if (e.descriptionError != null) errors.add('Diagnóstico ${i + 1}: ${e.descriptionError}');
    }
    return errors;
  }

  void dispose() {
    for (final entry in _entries.value) {
      entry.dispose();
    }
    _entries.dispose();
  }
}
