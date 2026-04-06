import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import 'cpf.dart';

/// Value Object para o Cartão Nacional de Saúde (CNS).
final class Cns with Equatable {
  const Cns._({
    required this.number,
    this.cpf,
    this.qrCode,
  });

  /// O número de 15 dígitos do CNS.
  final String number;
  
  /// Opcional: O CPF associado ao cartão CNS.
  final Cpf? cpf;
  
  /// Opcional: O QRCode associado ao CNS.
  final String? qrCode;

  @override
  List<Object?> get props => [number, cpf, qrCode];

  static Result<Cns> create({
    required String? number,
    Cpf? cpf,
    String? qrCode,
  }) {
    if (number == null || number.normalizedTrim().isEmpty) {
      return Failure(_buildError('CNS-001', 'Número do CNS não pode ser vazio.'));
    }

    final digits = number.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 15) {
      return Failure(
        _buildError('CNS-002', 'CNS deve conter exatamente 15 dígitos.'),
      );
    }

    if (!RegExp(r'^[12789]').hasMatch(digits[0])) {
      return Failure(
        _buildError('CNS-003', 'Primeiro dígito do CNS deve ser 1, 2, 7, 8 ou 9.'),
      );
    }

    if (!_isValidCns(digits)) {
      return Failure(
        _buildError('CNS-005', 'Dígito verificador do CNS é inválido.'),
      );
    }

    return Success(Cns._(
      number: digits,
      cpf: cpf,
      qrCode: qrCode?.nullIfEmptyTrimmed(),
    ));
  }

  static bool _isValidCns(String cns) {
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

  static AppError _buildError(String code, String message) {
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
}
