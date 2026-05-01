import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '../../../domain/errors/social_care_errors.dart';

/// Shared helpers for the split HttpSocialCareClient.
///
/// Extracted from the original 643-line god-service so each specialized
/// HTTP client (Registry, Assessment, Care, ...) can reuse them.
///
/// NOTE: this file is a pure organizational split — no logic changes.

/// Checks if a status code represents a successful response.
bool isSuccessStatus(int? statusCode) =>
    statusCode == 200 || statusCode == 201 || statusCode == 204;

/// Executes a PUT request expecting a void response (200 or 204).
Future<Result<void>> putVoid(Dio dio, String path, Object? data) async {
  try {
    final response = await dio.put<dynamic>(
      path,
      data: data,
      options: Options(validateStatus: (status) => true),
    );

    if (isSuccessStatus(response.statusCode)) {
      return const Success(null);
    }
    return failureFromResponse(response, 'Request failed');
  } catch (e) {
    return failureFromException(e);
  }
}

/// Parses a BFF error response into a typed [SocialCareError] [Failure].
///
/// The BFF forwards backend errors as `{"error": "CODE: message"}`.
/// This parser extracts the backend code and user-facing message,
/// then maps to domain errors when the code is known, or wraps in
/// [ServerError] otherwise.
Failure<T> failureFromResponse<T>(
  Response<dynamic> response,
  String fallback,
) {
  final statusCode = response.statusCode ?? 500;
  final data = response.data;
  String message = fallback;
  String code = 'SRV-$statusCode';

  if (data is Map<String, dynamic>) {
    final errorStr = data['error'] as String?;
    final messageStr = data['message'] as String?;

    // Parse backend code from "CODE: message" pattern
    if (errorStr != null) {
      final match = RegExp(r'^([A-Z]+-\d+):\s*(.*)$').firstMatch(errorStr);
      if (match != null) {
        code = match.group(1)!;
        final parsedMessage = match.group(2);
        message = (parsedMessage != null && parsedMessage.trim().isNotEmpty)
            ? parsedMessage
            : (messageStr ?? fallback);
      } else {
        message = messageStr ?? errorStr;
      }
    } else if (messageStr != null) {
      message = messageStr;
    }
  }

  return Failure(mapToSocialCareError(code, message, statusCode));
}

/// Maps a backend error code to the corresponding [SocialCareError].
///
/// Known codes are mapped to specific domain errors. Unknown codes
/// are wrapped in [ServerError] which carries the backend message
/// for the UI to display directly.
SocialCareError mapToSocialCareError(
  String code,
  String message,
  int httpStatus,
) {
  return switch (code) {
    // Registry — duplicate (backend code or HTTP status fallback)
    'REGP-001' || 'PAT-409' || 'SRV-409' => const DuplicatePatientError(),
    // Registry — validation
    'VAL-001' || 'PAT-003' => InvalidDataError(message),
    // Family — PR constraints
    'PAT-008' => const PrMemberRequiredError(),
    'PAT-009' => const MultiplePrimaryReferencesError(),
    // Everything else — pass the backend message through
    _ => ServerError(
      httpStatus: httpStatus,
      backendCode: code,
      backendMessage: message,
    ),
  };
}

/// Wraps a caught exception into a [SocialCareError] [Failure].
///
/// [DioException] with connection/timeout types become [NetworkError].
/// Everything else becomes [UnexpectedSocialCareError].
Failure<T> failureFromException<T>(Object e) {
  if (e is DioException) {
    final isNetwork = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
    if (isNetwork) {
      return Failure(NetworkError(e.message ?? e.type.name));
    }
  }
  return Failure(UnexpectedSocialCareError(e));
}

/// Maps a raw JSON map to an [AuditEvent].
AuditEvent mapAuditEvent(Map<String, dynamic> data) {
  final occurredAtResult = TimeStamp.fromIso(data['occurredAt'] as String);
  final recordedAtResult = TimeStamp.fromIso(data['recordedAt'] as String);

  final occurredAt = switch (occurredAtResult) {
    Success(:final value) => value,
    Failure(:final error) => unreachable(
      'Invalid occurredAt in audit event payload',
      module: 'social-care/audit-event',
      cause: error,
    ),
  };

  final recordedAt = switch (recordedAtResult) {
    Success(:final value) => value,
    Failure(:final error) => unreachable(
      'Invalid recordedAt in audit event payload',
      module: 'social-care/audit-event',
      cause: error,
    ),
  };

  return AuditEvent.reconstitute(
    id: data['id'] as String,
    aggregateId: data['aggregateId'] as String,
    eventType: data['eventType'] as String,
    actorId: data['actorId'] as String?,
    payload: data['payload'] as Map<String, dynamic>,
    occurredAt: occurredAt,
    recordedAt: recordedAt,
  );
}
