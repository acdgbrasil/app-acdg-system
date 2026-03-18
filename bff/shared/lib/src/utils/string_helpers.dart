/// Utilitários para normalização de strings, conforme definido em
/// `contracts/shared/validation-rules/_custom-validators.yaml` (normalize_text).
extension StringNormalization on String {
  /// Remove espaços em branco no início e no fim.
  String normalizedTrim() => trim();

  /// Colapsa múltiplos espaços em um único espaço.
  /// (regex \s+ → " ")
  String collapseWhitespace() => replaceAll(RegExp(r'\s+'), ' ');

  /// Aplica trim e collapseWhitespace.
  String normalize() => normalizedTrim().collapseWhitespace();

  /// Normaliza (apenas trim) e retorna nulo se a string ficar vazia.
  String? nullIfEmptyTrimmed() =>
      normalizedTrim().isEmpty ? null : normalizedTrim();

  /// Normaliza (trim + collapse) e retorna nulo se a string ficar vazia.
  String? nullIfEmptyNormalized() => normalize().isEmpty ? null : normalize();

  /// Converte camelCase para SNAKE_CASE_UPPER.
  /// Ex: homeVisit -> HOME_VISIT
  String toSnakeCaseUpper() {
    if (isEmpty) return this;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final char = this[i];
      if (char.toUpperCase() == char && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toUpperCase());
    }
    return buffer.toString();
  }
}
