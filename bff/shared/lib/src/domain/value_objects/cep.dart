import 'package:core/core.dart';

/// Value Object para o Código de Endereçamento Postal (CEP).
final class Cep with Equatable {
  const Cep._(this.value);

  /// O valor do CEP, contendo apenas os 8 dígitos numéricos.
  final String value;

  /// Retorna o CEP formatado (#####-###).
  String get formatted {
    return '${value.substring(0, 5)}-${value.substring(5, 8)}';
  }

  @override
  List<Object?> get props => [value];

  /// Tenta criar uma instância de [Cep].
  ///
  /// Retorna [Failure] se o valor for nulo, vazio ou não contiver 8 dígitos.
  static Result<Cep> create(String? input) {
    if (input == null || input.trim().isEmpty) {
      return const Failure('O CEP não pode estar vazio.');
    }

    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 8) {
      return const Failure('O CEP deve conter exatamente 8 dígitos.');
    }

    return Success(Cep._(digits));
  }
}
