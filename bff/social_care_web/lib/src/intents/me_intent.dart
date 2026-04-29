import 'package:core_contracts/core_contracts.dart';

/// Intent produced by `GET /auth/me` once the session cookie resolves.
final class MeIntent with Equatable {
  const MeIntent({required this.sessionId});

  /// Session identifier resolved from the `__Host-session` cookie.
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
