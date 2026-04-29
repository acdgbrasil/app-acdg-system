import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'backend_error.g.dart';

/// [cause] is self-recursive; Equatable handles transitive equality because
/// each nested [BackendError] is itself Equatable.
///
/// Note on [context] and [safeContext]: both are `Map<String, dynamic>?`.
/// Equatable compares maps structurally but cannot descend through `dynamic`
/// values, so deeply-nested payloads fall back to reference equality inside
/// the map values. Accepted limitation.
@JsonSerializable()
class BackendError with Equatable {
  const BackendError({
    required this.id,
    required this.code,
    required this.message,
    this.bc,
    this.module,
    this.kind,
    this.context,
    this.safeContext,
    this.observability,
    this.http,
    this.stackTrace,
    this.cause,
  });

  factory BackendError.fromJson(Map<String, dynamic> json) =>
      _$BackendErrorFromJson(json);

  final String id;
  final String code;
  final String message;
  final String? bc;
  final String? module;
  final String? kind;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? safeContext;
  final ErrorObservability? observability;
  final int? http;
  final String? stackTrace;
  final BackendError? cause;

  Map<String, dynamic> toJson() => _$BackendErrorToJson(this);

  @override
  List<Object?> get props => [
    id,
    code,
    message,
    bc,
    module,
    kind,
    context,
    safeContext,
    observability,
    http,
    stackTrace,
    cause,
  ];
}

@JsonSerializable()
class ErrorObservability with Equatable {
  const ErrorObservability({
    this.category,
    this.severity,
    this.fingerprint = const [],
    this.tags = const {},
  });

  factory ErrorObservability.fromJson(Map<String, dynamic> json) =>
      _$ErrorObservabilityFromJson(json);

  final String? category;
  final String? severity;
  final List<String> fingerprint;
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => _$ErrorObservabilityToJson(this);

  @override
  List<Object?> get props => [category, severity, fingerprint, tags];
}

@JsonSerializable()
class BackendErrorResponse with Equatable {
  const BackendErrorResponse({required this.error, this.details});

  factory BackendErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$BackendErrorResponseFromJson(json);

  final BackendError error;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => _$BackendErrorResponseToJson(this);

  @override
  List<Object?> get props => [error, details];
}
