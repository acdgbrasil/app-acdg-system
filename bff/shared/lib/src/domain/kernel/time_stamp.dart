import 'package:core/core.dart';
import '../../utils/app_error.dart';

/// Value Object que representa um timestamp em UTC, garantindo formatação ISO8601.
final class TimeStamp with Equatable implements Comparable<TimeStamp> {
  const TimeStamp._(this.date);

  /// A data encapsulada (sempre em UTC).
  final DateTime date;

  /// Retorna o momento atual em UTC.
  static TimeStamp get now => TimeStamp._(DateTime.now().toUtc());

  /// Tenta criar a partir de um [DateTime]. Se nulo, retorna erro `TS-001`.
  static Result<TimeStamp> fromDate(DateTime? date) {
    if (date == null) {
      return Failure(_buildError('TS-001', 'Data/hora não pode ser nula', 'invalidDate'));
    }
    return Success(TimeStamp._(date.toUtc()));
  }

  /// Tenta criar a partir de uma string ISO8601.
  static Result<TimeStamp> fromIso(String iso) {
    try {
      final parsed = DateTime.parse(iso).toUtc();
      return Success(TimeStamp._(parsed));
    } catch (_) {
      return Failure(_buildError('TS-001', 'Formato de data inválido. Esperado ISO8601.', 'invalidDate', context: {'value': iso}));
    }
  }

  /// Compara o dia civil em UTC (ignora horas).
  bool isSameDay(TimeStamp other) {
    return date.year == other.date.year &&
           date.month == other.date.month &&
           date.day == other.date.day;
  }

  /// Calcula a idade em anos completos na [referenceDate].
  int yearsAt({TimeStamp? referenceDate}) {
    final ref = referenceDate ?? TimeStamp.now;
    var age = ref.date.year - date.year;
    if (ref.date.month < date.month || (ref.date.month == date.month && ref.date.day < date.day)) {
      age--;
    }
    return age;
  }

  /// Retorna string ISO8601 (yyyy-MM-dd'T'HH:mm:ss.SSSZ)
  String toISOString() {
    return '${date.toIso8601String().split('Z').first}Z'; // Dart toIso8601String adds Z for UTC.
  }

  @override
  List<Object?> get props => [date];

  @override
  int compareTo(TimeStamp other) => date.compareTo(other.date);

  int get year => date.year;
  int get month => date.month;
  int get day => date.day;
  int get hour => date.hour;
  int get minute => date.minute;
  int get second => date.second;

  static AppError _buildError(String code, String message, String kind, {Map<String, dynamic> context = const {}}) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/timestamp',
      kind: kind,
      http: 422,
      context: context,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.error,
      ),
    );
  }
}
