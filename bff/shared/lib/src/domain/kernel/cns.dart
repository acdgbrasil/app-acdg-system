import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

/// Value Object para o Cartão Nacional de Saúde (CNS).
///
/// Extension type zero-cost sobre `String` (15 dígitos numéricos).
///
/// Nota arquitetural: a12b — A06d colapsou o antigo shape
/// `{ number, cpf, qrCode }` em um wrapper puro. O CPF do paciente vive
/// em `CivilDocuments.cpf`; o QR code (quando necessário) vive em
/// `CivilDocuments.cnsQrCode`.
extension type const Cns._(String value) {
  /// Origem garantida — zero-cost. Use com parcimônia.
  const Cns.trusted(String value) : this._(value);

  /// Factory validadora do número de 15 dígitos do CNS.
  static Result<Cns> create({required String? number}) {
    if (number == null || number.normalizedTrim().isEmpty) {
      return Failure(
        _buildCnsError('CNS-001', 'Número do CNS não pode ser vazio.'),
      );
    }

    final digits = number.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 15) {
      return Failure(
        _buildCnsError('CNS-002', 'CNS deve conter exatamente 15 dígitos.'),
      );
    }

    if (!RegExp(r'^[12789]').hasMatch(digits[0])) {
      return Failure(
        _buildCnsError(
          'CNS-003',
          'Primeiro dígito do CNS deve ser 1, 2, 7, 8 ou 9.',
        ),
      );
    }

    if (!_isValidCns(digits)) {
      return Failure(
        _buildCnsError('CNS-005', 'Dígito verificador do CNS é inválido.'),
      );
    }

    return Success(Cns._(digits));
  }
}

bool _isValidCns(String cns) {
  if (RegExp(r'^[1-3]').hasMatch(cns[0])) {
    String pis = cns.substring(0, 11);
    int soma = 0;
    for (int i = 0; i < 11; i++) {
      soma += int.parse(pis[i]) * (15 - i);
    }

    int resto = soma % 11;
    int dv = 11 - resto;

    if (dv == 11) dv = 0;

    String resultado;
    if (dv == 10) {
      soma += 2;
      resto = soma % 11;
      dv = 11 - resto;
      resultado = "${pis}001$dv";
    } else {
      resultado = "${pis}00$dv";
    }

    return cns == resultado;
  } else if (RegExp(r'^[7-9]').hasMatch(cns[0])) {
    int soma = 0;
    for (int i = 0; i < 15; i++) {
      soma += int.parse(cns[i]) * (15 - i);
    }
    return soma % 11 == 0;
  }

  return false;
}

AppError _buildCnsError(String code, String message) {
  return AppError(
    code: code,
    message: message,
    module: 'social-care/cns',
    kind: 'domainValidation',
    http: 422,
    observability: const Observability(
      category: ErrorCategory.domainRuleViolation,
      severity: ErrorSeverity.warning,
    ),
  );
}
