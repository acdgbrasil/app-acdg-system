import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

enum FiscalRegion {
  region10('RS'),
  region1('DF, GO, MS, MT, TO'),
  region2('AC, AM, AP, PA, RO, RR'),
  region3('CE, MA, PI'),
  region4('AL, PB, PE, RN'),
  region5('BA, SE'),
  region6('MG'),
  region7('ES, RJ'),
  region8('SP'),
  region9('PR, SC');

  const FiscalRegion(this.states);
  final String states;

  static FiscalRegion fromDigit(int digit) {
    return switch (digit) {
      0 => region10,
      1 => region1,
      2 => region2,
      3 => region3,
      4 => region4,
      5 => region5,
      6 => region6,
      7 => region7,
      8 => region8,
      9 => region9,
      _ => throw ArgumentError('Dígito fiscal inválido'),
    };
  }
}

/// Value Object para o Cadastro de Pessoas Físicas (CPF).
final class Cpf with Equatable {
  const Cpf._(this.value);

  /// 11 dígitos numéricos.
  final String value;

  String get baseNumber => value.substring(0, 8);
  int get fiscalRegionDigit => int.parse(value[8]);
  FiscalRegion get fiscalRegion => FiscalRegion.fromDigit(fiscalRegionDigit);
  int get firstVerifierDigit => int.parse(value[9]);
  int get secondVerifierDigit => int.parse(value[10]);

  String get formatted {
    return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9, 11)}';
  }

  @override
  List<Object?> get props => [value];

  static Result<Cpf> create(String? rawValue) {
    if (rawValue == null || rawValue.normalizedTrim().isEmpty) {
      return Failure(_buildError('CPF-001', 'O CPF não pode ser vazio.'));
    }

    final trimmed = rawValue.normalizedTrim();
    if (!RegExp(r'^[\d\.\-\s]+$').hasMatch(trimmed)) {
      return Failure(_buildError('CPF-005', "O CPF '$trimmed' contém caracteres inválidos."));
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return Failure(_buildError('CPF-001', 'O CPF não pode ser vazio.'));
    }

    if (digits.length != 11) {
      return Failure(_buildError('CPF-002', "O CPF '$trimmed' possui ${digits.length} dígitos. Esperado: 11."));
    }

    if (RegExp(r'^(.)\1*$').hasMatch(digits)) {
      return Failure(_buildError('CPF-003', "O CPF '$trimmed' possui todos os dígitos iguais."));
    }

    if (!_isValidMod11(digits)) {
      return Failure(_buildError('CPF-004', "O CPF '$trimmed' possui dígitos verificadores inválidos.", severity: ErrorSeverity.error));
    }

    return Success(Cpf._(digits));
  }

  static bool _isValidMod11(String digits) {
    final numbers = digits.split('').map(int.parse).toList();
    
    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += numbers[i] * (10 - i);
    }
    int rem1 = sum1 % 11;
    int digit1 = (rem1 < 2) ? 0 : 11 - rem1;
    if (numbers[9] != digit1) return false;

    int sum2 = 0;
    for (int i = 0; i < 10; i++) {
      sum2 += numbers[i] * (11 - i);
    }
    int rem2 = sum2 % 11;
    int digit2 = (rem2 < 2) ? 0 : 11 - rem2;
    if (numbers[10] != digit2) return false;

    return true;
  }

  static AppError _buildError(String code, String message, {ErrorSeverity severity = ErrorSeverity.warning}) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/cpf',
      kind: 'domainValidation',
      http: 422,
      observability: Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: severity,
      ),
    );
  }
}
