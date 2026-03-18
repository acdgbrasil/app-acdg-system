import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/config/oidc_config_factory.dart';
import 'logic/router/app_router.dart';
import 'logic/use_cases/auth_use_cases.dart';
import 'ui/view_models/auth_view_model.dart';

/// The Root widget of the application.
class Root extends StatefulWidget {
  const Root({
    super.key,
    this.authRepository,
    this.isarService,
    this.connectivityService,
  });

  final AuthRepository? authRepository;
  final IsarService? isarService;
  final ConnectivityService? connectivityService;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late final AuthRepository _authRepository;
  late final IsarService _isarService;
  late final ConnectivityService _connectivityService;
  late final SyncQueueService _syncQueueService;
  late final LocalSocialCareRepository _localSocialCareRepository;

  late final AppRouter _appRouter;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();

    _authRepository = widget.authRepository ??
        AuthRepositoryImpl(
          authService: OidcAuthService(
            config: OidcConfigFactory.fromEnvironment(),
          ),
        );

    _isarService = widget.isarService ?? IsarService();
    _connectivityService = widget.connectivityService ?? ConnectivityService();
    _syncQueueService = SyncQueueService(_isarService);
    _localSocialCareRepository = LocalSocialCareRepository(
      isarService: _isarService,
      queueService: _syncQueueService,
    );

    final loginUseCase = LoginUseCase(_authRepository);
    final logoutUseCase = LogoutUseCase(_authRepository);
    final restoreSessionUseCase = RestoreSessionUseCase(_authRepository);

    _authViewModel = AuthViewModel(
      authRepository: _authRepository,
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      restoreSessionUseCase: restoreSessionUseCase,
    );

    _appRouter = AppRouter(authViewModel: _authViewModel);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (widget.isarService == null) {
        await _isarService.init();
      }
      if (widget.connectivityService == null) {
        await _connectivityService.initialize();
      }
      await _authViewModel.init();
    } catch (e) {
      debugPrint('Initialization failed: $e');
      _authViewModel.status.value = AuthError('Falha ao inicializar o sistema: $e');
    }
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _authRepository.dispose();
    // Only close if we created it
    if (widget.isarService == null) _isarService.close();
    if (widget.connectivityService == null) _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider<AuthRepository>.value(value: _authRepository),
        Provider<IsarService>.value(value: _isarService),
        Provider<ConnectivityService>.value(value: _connectivityService),
        Provider<SyncQueueService>.value(value: _syncQueueService),
        Provider<LocalSocialCareRepository>.value(value: _localSocialCareRepository),

        ProxyProvider<AuthViewModel, SyncEngine?>(
          update: (context, auth, previous) {
            final authStatus = auth.status.value;
            if (authStatus is Authenticated) {
              final currentToken = auth.authRepository.currentToken;
              if (currentToken == null) return previous;

              final remote = SocialCareBffRemote(
                baseUrl: Env.bffBaseUrl,
                authToken: currentToken.accessToken,
                actorId: authStatus.user.id,
              );

              if (previous == null) {
                final engine = SyncEngine(
                  queueService: _syncQueueService,
                  connectivityService: _connectivityService,
                  remoteBff: remote,
                );
                engine.start();
                return engine;
              }
              return previous;
            }
            previous?.stop();
            return null;
          },
          dispose: (context, engine) => engine?.stop(),
        ),

        ProxyProvider2<AuthViewModel, SyncEngine?, SocialCareContract>(
          update: (context, auth, syncEngine, previous) {
            final authStatus = auth.status.value;
            
            if (authStatus is Authenticated && syncEngine != null) {
              final currentToken = auth.authRepository.currentToken;
              if (currentToken == null) return _localSocialCareRepository;

              final remote = SocialCareBffRemote(
                baseUrl: Env.bffBaseUrl,
                authToken: currentToken.accessToken,
                actorId: authStatus.user.id,
              );

              final repo = OfflineFirstRepository(
                local: _localSocialCareRepository,
                remote: remote,
                connectivity: _connectivityService,
                syncEngine: syncEngine,
              );

              unawaited(repo.prefetchLookupTables());

              return repo;
            }

            return _localSocialCareRepository;
          },
        ),

        Provider<LoginUseCase>(create: (context) => LoginUseCase(context.read<AuthRepository>())),
        Provider<LogoutUseCase>(create: (context) => LogoutUseCase(context.read<AuthRepository>())),
        Provider<RestoreSessionUseCase>(create: (context) => RestoreSessionUseCase(context.read<AuthRepository>())),
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
      ],
      child: MaterialApp.router(
        title: 'ACDG System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0477BF),
        ),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
