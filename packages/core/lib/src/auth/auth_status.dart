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
sealed class AuthStatus {
  const AuthStatus();
}

/// User is authenticated with a valid session.
final class Authenticated extends AuthStatus {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Authenticated && other.user == user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'Authenticated(${user.displayName})';
}

/// No active session — user must log in.
final class Unauthenticated extends AuthStatus {
  const Unauthenticated();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Unauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Unauthenticated';
}

/// Session is being checked or tokens are being refreshed.
final class AuthLoading extends AuthStatus {
  const AuthLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthLoading;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthLoading';
}

/// Authentication flow encountered an error.
final class AuthError extends AuthStatus {
  const AuthError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthError && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthError($message)';
}
