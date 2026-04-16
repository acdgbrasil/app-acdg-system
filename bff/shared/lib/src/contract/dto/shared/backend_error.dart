import 'package:json_annotation/json_annotation.dart';

part 'backend_error.g.dart';

@JsonSerializable()
class BackendError {
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
}

@JsonSerializable()
class ErrorObservability {
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
}

@JsonSerializable()
class BackendErrorResponse {
  const BackendErrorResponse({required this.error, this.details});

  factory BackendErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$BackendErrorResponseFromJson(json);

  final BackendError error;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => _$BackendErrorResponseToJson(this);
}
