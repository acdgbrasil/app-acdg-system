import 'package:design_system/design_system.dart';
import '../../view_models/housing_condition_view_model.dart';
import 'package:flutter/material.dart';
import '../../view_models/housing_condition_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/housing_condition_view_model.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/housing_condition_view_model.dart';

import '../../../shared/components/acdg_toast.dart';
import '../../view_models/housing_condition_view_model.dart';
import '../../di/housing_condition_providers.dart';
import '../../view_models/housing_condition_view_model.dart';
import '../components/housing_condition_action_bar.dart';
import '../../view_models/housing_condition_view_model.dart';
import '../components/housing_condition_content.dart';
import '../../view_models/housing_condition_view_model.dart';
import '../components/housing_condition_header.dart';
import '../../view_models/housing_condition_view_model.dart';
import '../components/housing_condition_nav_bar.dart';
import '../../view_models/housing_condition_view_model.dart';

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
    final vm = ref.read(housingConditionViewModelProvider(widget.patientId));
    vm.loadCommand.execute();
    vm.saveCommand.addListener(() => _onSaveStateChanged(vm));
  }

  void _onSaveStateChanged(HousingConditionViewModel vm) {
    if (!mounted) return;
    if (vm.saveCommand.completed) {
      AcdgToast.show(
        context,
        message: 'Dados salvos com sucesso!',
        type: ToastType.success,
      );
    } else if (vm.saveCommand.error) {
      AcdgToast.show(
        context,
        message: 'Falha ao salvar. Tente novamente.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(housingConditionViewModelProvider(widget.patientId));

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
                        style: const TextStyle(color: AppColors.danger),
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
