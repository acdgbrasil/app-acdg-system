import 'dart:async';
import 'package:flutter/foundation.dart';
import 'result.dart';

/// Base class for all commands.
///
/// Encapsulates an asynchronous action and exposes its state
/// (running, error, success) via [ChangeNotifier].
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;

  /// Whether the command is currently executing.
  bool get running => _running;

  Result<T>? _result;

  /// The result of the last execution.
  Result<T>? get result => _result;

  /// Whether the last execution failed.
  bool get error => _result is Failure;

  /// Whether the last execution succeeded.
  bool get completed => _result is Success;

  Future<void> _executeAction(Future<Result<T>> Function() action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

//TODO: MELHORAR ESSES NOMES PELO AMOR DE DEUS
/// A command that takes no arguments.
class Command0<T> extends Command<T> {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  Future<void> execute() async {
    await _executeAction(_action);
  }
}

/// A command that takes one argument of type [A].
class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  Future<void> execute(A arg) async {
    await _executeAction(() => _action(arg));
  }
}
