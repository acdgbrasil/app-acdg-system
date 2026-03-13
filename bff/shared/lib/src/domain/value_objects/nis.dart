import 'package:core/core.dart';

/// Value Object para o Número de Identificação Social (NIS/PIS/PASEP).
final class Nis with Equatable {
  const Nis._(this.value);

  /// O valor do NIS, contendo apenas os 11 dígitos numéricos.
  final String value;

  /// Retorna o NIS formatado (###.#####.##-#).
  String get formatted {
    return '${value.substring(0, 3)}.${value.substring(3, 8)}.${value.substring(8, 10)}-${value.substring(10, 11)}';
  }

  @override
  List<Object?> get props => [value];

  /// Tenta criar uma instância de [Nis].
  ///
  /// Retorna [Failure] se o valor for nulo, vazio, tiver o tamanho incorreto
  /// ou não for um NIS matematicamente válido.
  static Result<Nis> create(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const Failure('O NIS não pode estar vazio.');
    }

    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11) {
      return const Failure('O NIS deve conter exatamente 11 dígitos.');
    }

    if (RegExp(r'^(.)\1*$').hasMatch(digits)) {
      return const Failure('NIS inválido.');
    }

    if (!_isValidMod11(digits)) {
      return const Failure('NIS inválido.');
    }

    return Success(Nis._(digits));
  }

  static bool _isValidMod11(String digits) {
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
}
