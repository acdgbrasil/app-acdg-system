/// Utility to access environment variables.
///
/// Prioritizes values set via `--dart-define` (String.fromEnvironment)
/// and provides a consistent interface for the application.
class Env {
  const Env._();

  /// Reads a string environment variable.
  static String getString(String key, {String defaultValue = ''}) {
    final value = String.fromEnvironment(key);
    return value.isNotEmpty ? value : defaultValue;
  }

  /// Reads a boolean environment variable.
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  /// Reads an integer environment variable.
  static int getInt(String key, {int defaultValue = 0}) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// OIDC Configuration Keys
  static String get oidcIssuer => getString('OIDC_ISSUER');
  static String get oidcClientId => getString('OIDC_CLIENT_ID');
  static String get oidcWebRedirectUri => getString('OIDC_WEB_REDIRECT_URI');
  static String get oidcWebPostLogoutUri => getString('OIDC_WEB_POST_LOGOUT_URI');
}
