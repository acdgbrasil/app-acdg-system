import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity and validates actual internet access.
///
/// Combines [Connectivity] (network interface status) with a real 
/// internet "ping" check to provide a reliable [isOnline] status.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Dio? dio,
    this.checkUrl = 'https://www.google.com',
    this.checkInterval = const Duration(seconds: 5),
  })  : _connectivity = connectivity ?? Connectivity(),
        _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

  final Connectivity _connectivity;
  final Dio _dio;
  
  /// URL used to verify real internet access.
  final String checkUrl;
  
  /// Minimum time between real internet checks when network status changes.
  final Duration checkInterval;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  DateTime? _lastCheck;
  bool _isChecking = false;

  final ValueNotifier<bool> _online = ValueNotifier<bool>(true);

  /// Current connectivity state (Reliable: indicates actual internet access).
  ValueListenable<bool> get isOnline => _online;

  /// Stream of connectivity changes.
  Stream<bool> get onStatusChange => _online.toStream();

  /// Starts monitoring connectivity.
  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    await _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) {
      _online.value = false;
      return;
    }

    // If we have an interface, we must verify if internet is actually working.
    await checkRealInternet();
  }

  /// Manually forces a check for real internet access.
  /// 
  /// Performs a lightweight HEAD request to [checkUrl].
  Future<bool> checkRealInternet() async {
    if (_isChecking) return _online.value;
    
    // Throttle checks to avoid spamming the network
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < checkInterval) {
      return _online.value;
    }

    _isChecking = true;
    try {
      // Lightweight request to verify access
      final response = await _dio.head(checkUrl);
      final hasInternet = response.statusCode != null && response.statusCode! < 400;
      
      _online.value = hasInternet;
      _lastCheck = now;
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
    _online.dispose();
  }
}

extension _ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() {
    final controller = StreamController<T>.broadcast();
    void listener() => controller.add(value);
    addListener(listener);
    controller.onCancel = () => removeListener(listener);
    return controller.stream;
  }
}
