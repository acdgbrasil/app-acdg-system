import 'package:core/core.dart';

enum ErrorCategory {
  domainRuleViolation,
  externalApiFailure,
  externalContractMismatch,
  crossLayerCommunicationFailure,
  dataConsistencyIncident,
  securityBoundaryViolation,
  infrastructureDependencyFailure,
  observabilityPipelineFailure,
  unexpectedSystemState,
  conflict,
}

enum ErrorSeverity { debug, info, warning, error, critical }

class Observability with Equatable {
  const Observability({
    required this.category,
    required this.severity,
    this.fingerprint = const [],
    this.tags = const {},
  });

  final ErrorCategory category;
  final ErrorSeverity severity;
  final List<String> fingerprint;
  final Map<String, String> tags;

  @override
  List<Object?> get props => [category, severity, fingerprint, tags];
}

class AppError implements Exception {
  AppError({
    String? id,
    required this.code,
    required this.message,
    this.bc = 'social-care',
    required this.module,
    required this.kind,
    this.context = const {},
    this.safeContext = const {},
    required this.observability,
    this.http,
    this.stackTrace,
    this.cause,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  final String code;
  final String message;
  final String bc;
  final String module;
  final String kind;
  final Map<String, dynamic> context;
  final Map<String, dynamic> safeContext;
  final Observability observability;
  final int? http;
  final String? stackTrace;
  final Object? cause;

  @override
  String toString() => '[$code] $message ($module::$kind)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppError) return false;
    return id == other.id ||
        (code == other.code && bc == other.bc && module == other.module);
  }

  @override
  int get hashCode =>
      id.hashCode ^ code.hashCode ^ bc.hashCode ^ module.hashCode;
}

abstract interface class AppErrorConvertible {
  AppError get asAppError;
}
