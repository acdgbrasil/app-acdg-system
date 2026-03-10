import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_view_model.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConectaRarosApp());
}

class ConectaRarosApp extends StatefulWidget {
  const ConectaRarosApp({super.key, this.authService});

  /// Optional [AuthService] for testing. When null, the production
  /// OidcAuthService will be created (Etapa 2 — OidcAuthService).
  final AuthService? authService;

  @override
  State<ConectaRarosApp> createState() => _ConectaRarosAppState();
}

class _ConectaRarosAppState extends State<ConectaRarosApp> {
  late final AuthService _authService;
  late final AuthViewModel _authViewModel;
  late final AppRouter _appRouter;
  late final OidcAuthService? _oidcService;

  @override
  void initState() {
    super.initState();
    if (widget.authService != null) {
      _authService = widget.authService!;
      _oidcService = null;
    } else {
      final oidc = OidcAuthService(config: _buildConfig());
      _oidcService = oidc;
      _authService = oidc;
    }
    _authViewModel = AuthViewModel(authService: _authService);
    _appRouter = AppRouter(authViewModel: _authViewModel);
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final oidc = _oidcService;
      if (oidc != null) {
        await oidc.init();
      }
      await _authViewModel.init();
    } catch (e) {
      debugPrint('Auth init failed: $e');
      // Surface the error so the UI can show it instead of infinite loading.
      _authViewModel.status.value = AuthError('Falha ao conectar: $e');
    }
  }

  OidcAuthConfig _buildConfig() {
    // Injected via --dart-define at build time. Never hardcoded.
    const issuer = String.fromEnvironment('OIDC_ISSUER');
    const clientId = String.fromEnvironment('OIDC_CLIENT_ID');

    if (issuer.isEmpty || clientId.isEmpty) {
      throw StateError(
        'Missing OIDC configuration. '
        'Build with: flutter run --dart-define=OIDC_ISSUER=https://... '
        '--dart-define=OIDC_CLIENT_ID=...',
      );
    }

    // Platform-specific redirect URIs.
    // macOS uses flutter_appauth (ASWebAuthenticationSession) which requires
    // a fixed redirect URI. Windows/Linux use loopback listener (port 0 = random).
    final Uri redirectUri;
    final Uri postLogoutUri;

    if (PlatformResolver.isWeb) {
      const webCallback = String.fromEnvironment('OIDC_WEB_REDIRECT_URI');
      const webLogout = String.fromEnvironment('OIDC_WEB_POST_LOGOUT_URI');
      redirectUri = Uri.parse(webCallback.isNotEmpty
          ? webCallback
          : '$issuer/callback');
      postLogoutUri = Uri.parse(webLogout.isNotEmpty
          ? webLogout
          : issuer);
    } else if (PlatformResolver.isMacOS) {
      redirectUri = Uri.parse('com.acdg.conectararos://callback');
      postLogoutUri = Uri.parse('com.acdg.conectararos://logout');
    } else {
      // Windows/Linux: loopback listener picks a random port.
      redirectUri = Uri.parse('http://localhost:0');
      postLogoutUri = Uri.parse('http://localhost:0');
    }

    return OidcAuthConfig(
      issuer: Uri.parse(issuer),
      clientId: clientId,
      redirectUri: redirectUri,
      postLogoutRedirectUri: postLogoutUri,
    );
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authViewModel),
      ],
      child: MaterialApp.router(
        title: 'Conecta Raros',
        debugShowCheckedModeBanner: false,
        theme: AcdgTheme.light,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
