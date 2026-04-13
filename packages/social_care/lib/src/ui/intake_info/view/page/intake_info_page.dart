import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/intake_info_providers.dart';
import '../components/intake_info_action_bar.dart';
import '../components/intake_info_content.dart';
import '../components/intake_info_header.dart';
import '../components/intake_info_nav_bar.dart';

class IntakeInfoPage extends ConsumerStatefulWidget {
  const IntakeInfoPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<IntakeInfoPage> createState() => _IntakeInfoPageState();
}

class _IntakeInfoPageState extends ConsumerState<IntakeInfoPage> {
  @override
  void initState() {
    super.initState();
    final vm = ref.read(intakeInfoViewModelProvider(widget.patientId));
    vm.loadCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(intakeInfoViewModelProvider(widget.patientId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const IntakeInfoNavBar(),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) =>
                  IntakeInfoHeader(patientName: vm.patientName),
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
                  return IntakeInfoContent(viewModel: vm);
                },
              ),
            ),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => IntakeInfoActionBar(
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
