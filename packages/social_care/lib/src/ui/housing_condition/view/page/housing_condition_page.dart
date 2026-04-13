import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/housing_condition_providers.dart';
import '../components/housing_condition_action_bar.dart';
import '../components/housing_condition_content.dart';
import '../components/housing_condition_header.dart';
import '../components/housing_condition_nav_bar.dart';

class HousingConditionPage extends ConsumerStatefulWidget {
  const HousingConditionPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<HousingConditionPage> createState() =>
      _HousingConditionPageState();
}

class _HousingConditionPageState extends ConsumerState<HousingConditionPage> {
  @override
  void initState() {
    super.initState();
    final vm = ref.read(
      housingConditionViewModelProvider(widget.patientId),
    );
    vm.loadCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(
      housingConditionViewModelProvider(widget.patientId),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HousingConditionNavBar(),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) =>
                  HousingConditionHeader(patientName: vm.patientName),
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
                  return HousingConditionContent(viewModel: vm);
                },
              ),
            ),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => HousingConditionActionBar(
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
