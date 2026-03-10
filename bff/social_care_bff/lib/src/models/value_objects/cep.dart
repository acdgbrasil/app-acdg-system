/// Brazilian CEP (Codigo de Enderecamento Postal) value object.
///
/// Wraps a raw string and provides validation and formatting.
/// Does NOT throw on invalid input — the backend is the authority
/// for domain validation.
final class Cep {
  const Cep(this.value);

  final String value;

  static final _digitsOnly = RegExp(r'^\d{8}$');

  /// Whether the value has 8 digits (format check only).
  bool get isValid => _digitsOnly.hasMatch(value);

  /// Formatted as `XXXXX-XXX`. Returns raw value if invalid.
  String get formatted {
    if (!isValid) return value;
    return '${value.substring(0, 5)}-${value.substring(5)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cep && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Cep($value)';
}
