import 'package:core_contracts/core_contracts.dart';

/// Intent produced by `POST /auth/logout` once the session cookie resolves.
///
/// The [sessionId] is opaque to the UseCase — the BFF relies on the
/// [AuthContract] implementation to map it to upstream revocation calls.
final class LogoutIntent with Equatable {
  const LogoutIntent({required this.sessionId});

  /// Session identifier resolved from the `__Host-session` cookie.
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
