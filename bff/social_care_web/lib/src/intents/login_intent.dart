import 'package:core_contracts/core_contracts.dart';

/// Intent to initiate an OIDC login flow against Zitadel.
///
/// Produced from the `GET /auth/login` query string. The optional [returnTo]
/// preserves the URL the APP wanted to reach so the BFF can redirect back
/// after the callback completes.
final class LoginIntent with Equatable {
  const LoginIntent({this.returnTo});

  /// Optional post-login redirect target (path on the app origin).
  final String? returnTo;

  @override
  List<Object?> get props => [returnTo];

  /// Parses a shelf query map into a [LoginIntent] using P2 if-case.
  ///
  /// Empty/whitespace-only [returnTo] values are coerced to `null` — they
  /// carry no intent and we don't want to echo empty strings downstream.
  factory LoginIntent.parseFromQuery(Map<String, String> query) {
    if (query case {'returnTo': final String raw} when raw.trim().isNotEmpty) {
      return LoginIntent(returnTo: raw);
    }
    return const LoginIntent();
  }
}
