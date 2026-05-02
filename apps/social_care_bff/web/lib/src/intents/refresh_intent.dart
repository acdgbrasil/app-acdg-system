import 'package:core_contracts/core_contracts.dart';

/// Intent produced by `POST /auth/refresh` once the session cookie resolves.
final class RefreshIntent with Equatable {
  const RefreshIntent({required this.sessionId});

  /// Session identifier resolved from the `__Host-session` cookie.
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
