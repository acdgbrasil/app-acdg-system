import '../domain/kernel/time_stamp.dart';

/// Extensões para facilitar o mapeamento de TimeStamp para formatos esperados pelas APIs.
extension TimeStampApiExtensions on TimeStamp {
  /// Retorna o formato ISO8601 completo (ex: 2023-10-27T10:00:00.000Z).
  /// Útil para timestamps precisos e diagnósticos.
  String toIso8601() => toISOString();

  /// Retorna apenas a data (YYYY-MM-DD).
  /// Útil para campos que não requerem precisão de horário (ex: data de nascimento).
  String toShortDate() => toISOString().split('T').first;
}
