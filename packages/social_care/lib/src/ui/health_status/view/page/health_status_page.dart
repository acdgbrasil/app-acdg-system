import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/health_status_providers.dart';
import '../components/health_status_action_bar.dart';
import '../components/health_status_content.dart';
import '../components/health_status_header.dart';
import '../components/health_status_nav_bar.dart';

class HealthStatusPage extends ConsumerStatefulWidget {
  const HealthStatusPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<HealthStatusPage> createState() => _HealthStatusPageState();
}

class _HealthStatusPageState extends ConsumerState<HealthStatusPage> {
  @override
  void initState() {
    super.initState();
    final vm = ref.read(healthStatusViewModelProvider(widget.patientId));
    vm.loadCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(healthStatusViewModelProvider(widget.patientId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HealthStatusNavBar(),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) =>
                  HealthStatusHeader(patientName: vm.patientName),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: vm.loadCommand,
                builder: (context, _) {
                  if (vm.loadCommand.running) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (vm.errorMessage != null && !vm.hasData) {
                    return Center(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return HealthStatusContent(viewModel: vm);
                },
              ),
            ),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => HealthStatusActionBar(
                canSave: vm.canSave,
                onCancel: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/social-care');
                  }
                },
                onSave: () => vm.saveCommand.execute(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
