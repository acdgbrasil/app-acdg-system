import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

/// Value Object para o Número de Identificação Social (NIS/PIS/PASEP).
///
/// Extension type zero-cost sobre `String` (11 dígitos numéricos).
extension type const Nis._(String value) {
  /// Origem garantida — zero-cost. Use com parcimônia.
  const Nis.trusted(String value) : this._(value);

  String get formatted {
    return '${value.substring(0, 3)}.${value.substring(3, 8)}.${value.substring(8, 10)}-${value.substring(10, 11)}';
  }

  static Result<Nis> create(String? rawValue) {
    if (rawValue == null || rawValue.normalizedTrim().isEmpty) {
      return Failure(_buildNisError('NIS-001', 'O NIS não pode ser vazio.'));
    }

    final digits = rawValue.normalizedTrim().replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return Failure(_buildNisError('NIS-001', 'O NIS não pode ser vazio.'));
    }

    if (digits.length != 11) {
      return Failure(
        _buildNisError(
          'NIS-002',
          "O NIS '${rawValue.normalizedTrim()}' possui ${digits.length} dígitos. Esperado: 11.",
        ),
      );
    }

    if (RegExp(r'^(.)\1*$').hasMatch(digits)) {
      return Failure(
        _buildNisError(
          'NIS-002',
          "O NIS '${rawValue.normalizedTrim()}' é inválido.",
        ),
      );
    }

    if (!_isValidNisMod11(digits)) {
      return Failure(
        _buildNisError(
          'NIS-002',
          "O NIS '${rawValue.normalizedTrim()}' é inválido.",
        ),
      );
    }

    return Success(Nis._(digits));
  }
}

bool _isValidNisMod11(String digits) {
  final numbers = digits.split('').map(int.parse).toList();
  final weights = [3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  int sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += numbers[i] * weights[i];
  }

  int rem = sum % 11;
  int digit = (rem < 2) ? 0 : 11 - rem;

  return numbers[10] == digit;
}

AppError _buildNisError(String code, String message) {
  return AppError(
    code: code,
    message: message,
    module: 'social-care/nis',
    kind: 'domainValidation',
    http: 422,
    observability: const Observability(
      category: ErrorCategory.domainRuleViolation,
      severity: ErrorSeverity.warning,
    ),
  );
}
