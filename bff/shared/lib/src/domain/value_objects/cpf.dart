import 'package:core/core.dart';

/// Value Object para o Cadastro de Pessoas Físicas (CPF).
final class Cpf with Equatable {
  const Cpf._(this.value);

  /// O valor do CPF, contendo apenas os 11 dígitos numéricos.
  final String value;

  /// Retorna o CPF formatado (###.###.###-##).
  String get formatted {
    return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9, 11)}';
  }

  @override
  List<Object?> get props => [value];

  /// Tenta criar uma instância de [Cpf].
  ///
  /// Retorna [Failure] se o valor for nulo, vazio, tiver o tamanho incorreto
  /// ou não for um CPF matematicamente válido.
  static Result<Cpf> create(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const Failure('O CPF não pode estar vazio.');
    }

    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11) {
      return const Failure('O CPF deve conter exatamente 11 dígitos.');
    }

    if (_isBlacklisted(digits) || !_isValidMod11(digits)) {
      return const Failure('CPF inválido.');
    }

    return Success(Cpf._(digits));
  }

  static bool _isBlacklisted(String digits) {
    // Rejeita CPFs com todos os dígitos iguais
    return RegExp(r'^(.)\1*$').hasMatch(digits);
  }

  static bool _isValidMod11(String digits) {
    final numbers = digits.split('').map(int.parse).toList();
    
    // Calcula primeiro dígito verificador
    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += numbers[i] * (10 - i);
    }
    int rem1 = sum1 % 11;
    int digit1 = (rem1 < 2) ? 0 : 11 - rem1;
    if (numbers[9] != digit1) return false;

    // Calcula segundo dígito verificador
    int sum2 = 0;
    for (int i = 0; i < 10; i++) {
      sum2 += numbers[i] * (11 - i);
    }
    int rem2 = sum2 % 11;
    int digit2 = (rem2 < 2) ? 0 : 11 - rem2;
    if (numbers[10] != digit2) return false;

    return true;
  }
}
