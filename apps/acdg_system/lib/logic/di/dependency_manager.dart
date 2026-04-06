import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/core_offline.dart';
import 'package:network/network.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import '../../data/config/auth_config_factory.dart';
import '../use_cases/auth_use_cases.dart';

/// Orchestrates the creation and lifecycle of the application's core dependencies.
///
/// On **desktop**, initialises the full offline-first stack (Drift DB,
/// SyncQueue, LocalSocialCareRepository, ConnectivityService).
///
/// On **web**, the offline layer is skipped — the BFF handles persistence
/// server-side and auth uses HttpOnly session cookies.
class AppDependencyManager {
  AppDependencyManager({
    AuthRepository? authRepository,
    DriftDatabaseService? dbService,
    ConnectivityService? connectivityService,
  }) {
    _isWeb = PlatformResolver.isWeb;

    if (!_isWeb) {
      _dbService = dbService ?? DriftDatabaseService();
      _connectivityService = connectivityService ?? ConnectivityService();
    }

    _authRepository =
        authRepository ??
        AuthRepositoryImpl(
          authService: AuthConfigFactory.createAuthService(),
        );
  }

  late final bool _isWeb;
  late final AuthRepository _authRepository;

  // Desktop-only infrastructure (null on web)
  DriftDatabaseService? _dbService;
  ConnectivityService? _connectivityService;
  SyncQueueService? _syncQueueService;
  LocalSocialCareRepository? _localSocialCareRepository;

  // Use Cases
  late final LoginUseCase _loginUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final RestoreSessionUseCase _restoreSessionUseCase;

  // Getters — auth (all platforms)
  AuthRepository get authRepository => _authRepository;
  LoginUseCase get loginUseCase => _loginUseCase;
  LogoutUseCase get logoutUseCase => _logoutUseCase;
  RestoreSessionUseCase get restoreSessionUseCase => _restoreSessionUseCase;

  /// Whether the app is running on web.
  bool get isWeb => _isWeb;

  // Getters — desktop-only (throw on web to catch wiring bugs early)
  DriftDatabaseService get dbService {
    assert(!_isWeb, 'dbService is not available on web');
    return _dbService!;
  }

  ConnectivityService get connectivityService {
    assert(!_isWeb, 'connectivityService is not available on web');
    return _connectivityService!;
  }

  SyncQueueService get syncQueueService {
    assert(!_isWeb, 'syncQueueService is not available on web');
    return _syncQueueService!;
  }

  LocalSocialCareRepository get localSocialCareRepository {
    assert(!_isWeb, 'localSocialCareRepository is not available on web');
    return _localSocialCareRepository!;
  }

  /// Performs the initial asynchronous setup of services.
  Future<void> initialize() async {
    if (!_isWeb) {
      if (!_dbService!.isOpen) {
        await _dbService!.init();
      }
      await _connectivityService!.initialize();

      _syncQueueService = SyncQueueService(_dbService!);
      _localSocialCareRepository = LocalSocialCareRepository(
        dbService: _dbService!,
        queueService: _syncQueueService!,
      );
    }

    _loginUseCase = LoginUseCase(_authRepository);
    _logoutUseCase = LogoutUseCase(_authRepository);
    _restoreSessionUseCase = RestoreSessionUseCase(_authRepository);

    await _authRepository.init();
  }

  Future<void> dispose() async {
    _authRepository.dispose();
    if (!_isWeb) {
      await _dbService?.close();
      _connectivityService?.dispose();
    }
  }
}
