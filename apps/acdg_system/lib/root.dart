import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';

import 'logic/di/app_providers.dart';
import 'logic/di/dependency_manager.dart';
import 'ui/app_view.dart';
import 'ui/widgets/boot_views.dart';

enum _BootStatus { loading, ready, error }

/// The entry point of the application after main().
/// Orchestrates the asynchronous initialization of core infrastructure.
class Root extends StatefulWidget {
  const Root({
    super.key,
    this.authRepository,
    this.dbService,
    this.connectivityService,
  });

  final AuthRepository? authRepository;
  final DriftDatabaseService? dbService;
  final ConnectivityService? connectivityService;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late final AppDependencyManager _deps;
  _BootStatus _status = _BootStatus.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deps = AppDependencyManager(
      authRepository: widget.authRepository,
      dbService: widget.dbService,
      connectivityService: widget.connectivityService,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _deps.initialize();
      if (mounted) setState(() => _status = _BootStatus.ready);
    } catch (e) {
      debugPrint('Bootstrap error: $e');
      if (mounted) {
        setState(() {
          _status = _BootStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _deps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _BootStatus.loading => const LoadingView(),
      _BootStatus.error => ErrorView(
        message: _errorMessage ?? 'Erro desconhecido',
        onRetry: () {
          setState(() => _status = _BootStatus.loading);
          _initialize();
        },
      ),
      _BootStatus.ready => AppProviders(deps: _deps, child: const AppView()),
    };
  }
}
