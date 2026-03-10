/// Brazilian NIS (Numero de Identificacao Social) value object.
///
/// Also known as PIS/PASEP/NIT. Wraps a raw string and provides
/// validation. Does NOT throw on invalid input — the backend is
/// the authority for domain validation.
final class Nis {
  const Nis(this.value);

  final String value;

  static final _digitsOnly = RegExp(r'^\d{11}$');

  /// Whether the value has 11 digits (format check only).
  bool get isValid => _digitsOnly.hasMatch(value);

  /// Formatted as `XXX.XXXXX.XX-X`. Returns raw value if invalid.
  String get formatted {
    if (!isValid) return value;
    return '${value.substring(0, 3)}'
        '.${value.substring(3, 8)}'
        '.${value.substring(8, 10)}'
        '-${value.substring(10)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Nis && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Nis($value)';
}
