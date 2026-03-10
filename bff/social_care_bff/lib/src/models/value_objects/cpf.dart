/// Brazilian CPF (Cadastro de Pessoas Fisicas) value object.
///
/// Wraps a raw string and provides validation and formatting.
/// Does NOT throw on invalid input — the backend is the authority
/// for domain validation. Use [isValid] for client-side checks.
final class Cpf {
  const Cpf(this.value);

  final String value;

  static final _digitsOnly = RegExp(r'^\d{11}$');

  /// Whether the value has 11 digits (format check only).
  bool get isValid => _digitsOnly.hasMatch(value);

  /// Formatted as `XXX.XXX.XXX-XX`. Returns raw value if invalid.
  String get formatted {
    if (!isValid) return value;
    return '${value.substring(0, 3)}'
        '.${value.substring(3, 6)}'
        '.${value.substring(6, 9)}'
        '-${value.substring(9)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cpf && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Cpf($value)';
}
