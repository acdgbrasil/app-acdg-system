import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /team` — register a new team professional.
///
/// Wraps the typed [RegisterPersonWithLoginRequest] payload built from the
/// request body. The endpoint orchestrates a composite transaction inside
/// the BFF (PeopleContext registration + worker record + initial role) —
/// the APP only sees a single round trip and a generated `id`.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 3 required
/// top-level strings (`fullName`, `birthDate`, `email`) plus 2 optional
/// strings (`cpf`, `initialPassword`). No nested required sub-DTOs, so the
/// canonical **P2 if-case manual** path is used.
///
/// PII-safety (CRITICAL): `fullName`, `birthDate`, `email`, `cpf`, and
/// `initialPassword` are all PII-dense — and `initialPassword` is a
/// secret. [parseFromBody] failures NEVER echo any of these values back
/// to the caller. The error only enumerates the missing / empty required
/// field NAMES; raw content is dropped at the boundary.
final class RegisterWorkerIntent with Equatable {
  const RegisterWorkerIntent({required this.request});

  final RegisterPersonWithLoginRequest request;

  @override
  List<Object?> get props => [request];

  /// Parses a decoded JSON body into an intent.
  ///
  /// Enforces the 3 required fields (`fullName`, `birthDate`, `email`)
  /// as non-empty strings. `cpf` and `initialPassword` are optional and
  /// passed through verbatim. Missing required fields produce a [Failure]
  /// whose message enumerates the field names WITHOUT echoing any raw
  /// value.
  static Result<RegisterWorkerIntent> parseFromBody(
    Map<String, dynamic> body,
  ) {
    final fullNameRaw = body['fullName'];
    final birthDateRaw = body['birthDate'];
    final emailRaw = body['email'];

    final fullName = fullNameRaw is String && fullNameRaw.isNotEmpty
        ? fullNameRaw
        : null;
    final birthDate = birthDateRaw is String && birthDateRaw.isNotEmpty
        ? birthDateRaw
        : null;
    final email = emailRaw is String && emailRaw.isNotEmpty ? emailRaw : null;

    final missing = <String>[];
    if (fullName == null) missing.add('fullName');
    if (birthDate == null) missing.add('birthDate');
    if (email == null) missing.add('email');

    if (missing.isEmpty) {
      final request = RegisterPersonWithLoginRequest(
        fullName: fullName!,
        birthDate: birthDate!,
        email: email!,
        cpf: _asString(body['cpf']),
        initialPassword: _asString(body['initialPassword']),
      );
      return Success(RegisterWorkerIntent(request: request));
    }

    return Failure(
      _RegisterWorkerParseError(
        'Invalid register-worker body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [RegisterWorkerIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`fullName`, `birthDate`,
/// `email`, `cpf`, `initialPassword`) so the error cannot be weaponized
/// to leak professional PII or initial credentials via logs / error
/// responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _RegisterWorkerParseError with Equatable implements Exception {
  _RegisterWorkerParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
