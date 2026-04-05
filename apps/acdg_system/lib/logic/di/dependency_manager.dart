import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/core_offline.dart';
import 'package:network/network.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import '../../data/config/oidc_config_factory.dart';
import '../use_cases/auth_use_cases.dart';

/// Orchestrates the creation and lifecycle of the application's core dependencies.
class AppDependencyManager {
  AppDependencyManager({
    AuthRepository? authRepository,
    DriftDatabaseService? dbService,
    ConnectivityService? connectivityService,
  }) {
    _dbService = dbService ?? DriftDatabaseService();
    _connectivityService = connectivityService ?? ConnectivityService();

    _authRepository =
        authRepository ??
        AuthRepositoryImpl(
          authService: OidcAuthService(
            config: OidcConfigFactory.fromEnvironment(),
          ),
        );
  }

  late final AuthRepository _authRepository;
  late final DriftDatabaseService _dbService;
  late final ConnectivityService _connectivityService;

  // Infrastructure & Logic
  late final SyncQueueService _syncQueueService;
  late final LocalSocialCareRepository _localSocialCareRepository;

  // Use Cases
  late final LoginUseCase _loginUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final RestoreSessionUseCase _restoreSessionUseCase;

  // Getters
  AuthRepository get authRepository => _authRepository;
  DriftDatabaseService get dbService => _dbService;
  ConnectivityService get connectivityService => _connectivityService;
  SyncQueueService get syncQueueService => _syncQueueService;
  LocalSocialCareRepository get localSocialCareRepository =>
      _localSocialCareRepository;

  LoginUseCase get loginUseCase => _loginUseCase;
  LogoutUseCase get logoutUseCase => _logoutUseCase;
  RestoreSessionUseCase get restoreSessionUseCase => _restoreSessionUseCase;

  /// Performs the initial asynchronous setup of services.
  Future<void> initialize() async {
    if (!_dbService.isOpen) {
      await _dbService.init();
    }
    await _connectivityService.initialize();

    _syncQueueService = SyncQueueService(_dbService);
    _localSocialCareRepository = LocalSocialCareRepository(
      dbService: _dbService,
      queueService: _syncQueueService,
    );

    _loginUseCase = LoginUseCase(_authRepository);
    _logoutUseCase = LogoutUseCase(_authRepository);
    _restoreSessionUseCase = RestoreSessionUseCase(_authRepository);

    await _authRepository.init();
  }

  Future<void> dispose() async {
    _authRepository.dispose();
    await _dbService.close();
    _connectivityService.dispose();
  }
}
