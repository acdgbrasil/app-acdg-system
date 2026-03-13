import 'package:core/core.dart';

import 'auth_user.dart';

/// Authentication state of the application.
///
/// Sealed class ensuring exhaustive handling via pattern matching:
/// ```dart
/// switch (status) {
///   case Authenticated(:final user): // logged in
///   case Unauthenticated(): // logged out or session expired
///   case AuthLoading(): // checking session or refreshing
///   case AuthError(:final message): // auth flow failed
/// }
/// ```
sealed class AuthStatus with Equatable {
  const AuthStatus();
}

/// User is authenticated with a valid session.
final class Authenticated extends AuthStatus {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];

  @override
  String toString() => 'Authenticated(${user.displayName})';
}

/// No active session — user must log in.
final class Unauthenticated extends AuthStatus {
  const Unauthenticated();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'Unauthenticated';
}

/// Session is being checked or tokens are being refreshed.
final class AuthLoading extends AuthStatus {
  const AuthLoading();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'AuthLoading';
}

/// Authentication flow encountered an error.
final class AuthError extends AuthStatus {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthError($message)';
}
