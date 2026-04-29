import 'package:core_contracts/core_contracts.dart';

import '../dto/responses/auth/me_response.dart';
import '../dto/shared/standard_response.dart';

/// Auth contract — OIDC session lifecycle with Zitadel.
///
/// The BFF owns the OIDC flow (PKCE, tokens, session cookie). The APP
/// only calls these endpoints and receives cookies back — tokens never
/// reach the client.
abstract interface class AuthContract {
  /// Initiates the OIDC PKCE login flow.
  ///
  /// Returns the Zitadel redirect URL. The APP performs the browser
  /// redirect; the BFF persists the PKCE verifier and state in a
  /// short-lived cookie.
  Future<Result<String>> login();

  /// Handles the OIDC callback from Zitadel.
  ///
  /// Exchanges [code] for tokens, creates a session, and sets an
  /// `__Host-session` HttpOnly cookie. Returns a void payload — the
  /// session travels by cookie.
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  });

  /// Revokes the current session (server-side) and clears the cookie.
  Future<Result<StandardResponse<void>>> logout();

  /// Renews the access token using the stored refresh token.
  ///
  /// Transparent to the APP — called automatically by the BFF on
  /// expired tokens during proxied requests.
  Future<Result<StandardResponse<void>>> refresh();

  /// Returns the authenticated user's profile (id, email, roles).
  Future<Result<StandardResponse<MeResponse>>> me();
}
