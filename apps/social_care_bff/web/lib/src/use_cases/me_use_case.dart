import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/me_intent.dart';
import '../observability/observability_context.dart';

/// Resolves the authenticated user's profile via [AuthContract.me].
///
/// Unwraps the upstream [StandardResponse] and returns the [MeResponse]
/// payload directly so the handler can serialize it without double-wrapping.
///
/// Observability canon: `auth.me.received`, `auth.me.resolved`,
/// `auth.me.failed`. Email addresses are NEVER placed in breadcrumb data.
final class MeUseCase {
  const MeUseCase({required AuthContract auth}) : _auth = auth;

  final AuthContract _auth;

  Future<Result<MeResponse>> execute(
    MeIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('auth.me.received');

    final result = await _auth.me();

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb('auth.me.resolved');
        return Success<MeResponse>(value.data);
      }(),
      Failure(:final error, :final stackTrace) => () {
        obs.breadcrumb(
          'auth.me.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<MeResponse>(error, stackTrace: stackTrace);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
