import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the application.
///
/// Extends [ChangeNotifier] for integration with Provider.
/// Tracks [disposed] state to prevent late notifications.
///
/// Subclasses should override [onDispose] for cleanup logic
/// instead of overriding [dispose] directly.
abstract class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;

  /// Whether this ViewModel has been disposed.
  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Override this method to perform cleanup when the ViewModel is disposed.
  @protected
  void onDispose() {}

  @override
  @mustCallSuper
  void dispose() {
    _disposed = true;
    onDispose();
    super.dispose();
  }
}
