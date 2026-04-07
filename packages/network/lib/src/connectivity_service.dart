import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity and validates actual internet access.
///
/// Combines [Connectivity] (network interface status) with a real
/// internet "ping" check to provide a reliable [isOnline] status.
///
/// On desktop platforms (macOS, Windows, Linux), [connectivity_plus]
/// may not reliably detect network changes. A periodic real-internet
/// check runs as fallback to keep the status accurate.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Dio? dio,
    this.checkUrl = 'https://www.google.com',
    this.checkInterval = const Duration(seconds: 5),
    this.periodicCheckInterval = const Duration(seconds: 30),
  }) : _connectivity = connectivity ?? Connectivity(),
       _dio =
           dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

  final Connectivity _connectivity;
  final Dio _dio;

  /// URL used to verify real internet access.
  final String checkUrl;

  /// Minimum time between real internet checks when network status changes.
  final Duration checkInterval;

  /// Interval for periodic fallback check (desktop platforms).
  final Duration periodicCheckInterval;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;
  DateTime? _lastCheck;
  bool _isChecking = false;

  final ValueNotifier<bool> _online = ValueNotifier<bool>(false);

  /// Current connectivity state (Reliable: indicates actual internet access).
  ValueListenable<bool> get isOnline => _online;

  /// Manually set connectivity status for testing purposes.
  @visibleForTesting
  void setOnlineForTesting(bool value) {
    _online.value = value;
  }

  /// Stream of connectivity changes.
  Stream<bool> get onStatusChange => _online.toStream();

  /// Starts monitoring connectivity.
  Future<void> initialize() async {
    // 1. Try connectivity_plus first
    final results = await _connectivity.checkConnectivity();
    debugPrint('📡 ConnectivityService: connectivity_plus reported: $results');
    await _updateStatus(results);
    debugPrint(
      '📡 ConnectivityService: after _updateStatus → isOnline=${_online.value}',
    );

    // 2. Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);

    // 3. On desktop, connectivity_plus may not work reliably.
    //    Always do an initial real check + periodic fallback.
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      debugPrint(
        '📡 ConnectivityService: desktop detected — forcing real internet check',
      );
      final result = await checkRealInternet(force: true);
      debugPrint(
        '📡 ConnectivityService: real internet check → isOnline=$result',
      );

      // Periodic fallback — re-check every 30s on desktop
      _periodicTimer = Timer.periodic(periodicCheckInterval, (_) {
        checkRealInternet(force: true);
      });
    }
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) {
      // connectivity_plus says no interface — verify with real check
      // (on desktop this may be wrong, so we still try)
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await checkRealInternet(force: true);
      } else {
        _online.value = false;
      }
      return;
    }

    // If we have an interface, verify if internet is actually working.
    await checkRealInternet();
  }

  /// Manually forces a check for real internet access.
  ///
  /// Performs a lightweight HEAD request to [checkUrl].
  /// When [force] is true, ignores the throttle interval.
  Future<bool> checkRealInternet({bool force = false}) async {
    if (_isChecking) return _online.value;

    // Throttle checks to avoid spamming the network
    if (!force) {
      final now = DateTime.now();
      if (_lastCheck != null && now.difference(_lastCheck!) < checkInterval) {
        return _online.value;
      }
    }

    _isChecking = true;
    try {
      final response = await _dio.head<void>(checkUrl);
      final hasInternet =
          response.statusCode != null && response.statusCode! < 400;

      _online.value = hasInternet;
      _lastCheck = DateTime.now();
      return hasInternet;
    } catch (_) {
      _online.value = false;
      return false;
    } finally {
      _isChecking = false;
    }
  }

  /// Stops monitoring and releases resources.
  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
    _online.dispose();
  }
}

extension _ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() {
    final controller = StreamController<T>.broadcast();
    void listener() => controller.add(value);
    addListener(listener);
    controller.onCancel = () {
      removeListener(listener);
      controller.close();
    };
    return controller.stream;
  }
}
