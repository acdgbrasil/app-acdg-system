import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors network connectivity and exposes a listenable status.
///
/// Wraps [Connectivity] plugin to provide:
/// - Current status via [isOnline]
/// - Stream of changes via [onStatusChange]
/// - Dispose-safe lifecycle
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final ValueNotifier<bool> _online = ValueNotifier<bool>(true);

  /// Current connectivity state.
  ValueListenable<bool> get isOnline => _online;

  /// Stream of connectivity changes.
  Stream<bool> get onStatusChange => _online.toStream();

  /// Starts listening for connectivity changes.
  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _online.value = _hasConnection(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _online.value = _hasConnection(results);
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) => r != ConnectivityResult.none,
    );
  }

  /// Stops listening and releases resources.
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
