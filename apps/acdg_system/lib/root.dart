import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/config/oidc_config_factory.dart';
import 'logic/router/app_router.dart';
import 'logic/use_cases/auth_use_cases.dart';
import 'ui/view_models/auth_view_model.dart';

/// The Root widget of the application.
///
/// Orchestrates the three architecture layers:
/// 1. Data: Configures Repositories and Services.
/// 2. Logic: Instantiates UseCases and Routers.
/// 3. UI: Creates ViewModels and injects them via Provider.
class Root extends StatefulWidget {
  const Root({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  // Layer 1: Data
  late final AuthRepository _authRepository;

  // Layer 2: Logic (Router needs AuthViewModel)
  late final AppRouter _appRouter;

  // Layer 3: UI
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();

    // Data Initialization
    _authRepository = widget.authRepository ??
        AuthRepositoryImpl(
          authService: OidcAuthService(
            config: OidcConfigFactory.fromEnvironment(),
          ),
        );

    // Logic Initialization (UseCases)
    final loginUseCase = LoginUseCase(_authRepository);
    final logoutUseCase = LogoutUseCase(_authRepository);
    final restoreSessionUseCase = RestoreSessionUseCase(_authRepository);

    // UI Initialization (ViewModel dependent on Logic)
    _authViewModel = AuthViewModel(
      authRepository: _authRepository,
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      restoreSessionUseCase: restoreSessionUseCase,
    );

    // Router Initialization (dependent on UI state for redirects)
    _appRouter = AppRouter(authViewModel: _authViewModel);

    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      await _authViewModel.init();
    } catch (e) {
      debugPrint('Auth init failed: $e');
      _authViewModel.status.value = AuthError('Falha ao conectar: $e');
    }
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _authRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---------- DATA LAYER ----------
        ListenableProvider<AuthRepository>.value(value: _authRepository),

        // ---------- LOGIC LAYER (UseCases) ----------
        Provider<LoginUseCase>(
          create: (context) => LoginUseCase(context.read<AuthRepository>()),
        ),
        Provider<LogoutUseCase>(
          create: (context) => LogoutUseCase(context.read<AuthRepository>()),
        ),
        Provider<RestoreSessionUseCase>(
          create: (context) =>
              RestoreSessionUseCase(context.read<AuthRepository>()),
        ),

        // ---------- UI LAYER (ViewModels) ----------
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
      ],
      child: MaterialApp.router(
        title: 'ACDG System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: const Color(0xFF0477BF),
        ),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
