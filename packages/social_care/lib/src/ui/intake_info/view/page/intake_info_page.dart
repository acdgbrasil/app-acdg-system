
import 'package:design_system/design_system.dart';
import '../../view_models/intake_info_view_model.dart';
import 'package:flutter/material.dart';
import '../../view_models/intake_info_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/intake_info_view_model.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/intake_info_view_model.dart';

import '../../../shared/components/acdg_toast.dart';
import '../../view_models/intake_info_view_model.dart';
import '../../di/intake_info_providers.dart';
import '../../view_models/intake_info_view_model.dart';
import '../components/intake_info_action_bar.dart';
import '../../view_models/intake_info_view_model.dart';
import '../components/intake_info_content.dart';
import '../../view_models/intake_info_view_model.dart';
import '../components/intake_info_header.dart';
import '../../view_models/intake_info_view_model.dart';
import '../components/intake_info_nav_bar.dart';
import '../../view_models/intake_info_view_model.dart';

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
    print(
      '📱 initState — calling loadCommand.execute()',
    );
    final vm = ref.read(intakeInfoViewModelProvider(widget.patientId));
    vm.loadCommand.execute();
    vm.saveCommand.addListener(() => _onSaveStateChanged(vm));
  }

  void _onSaveStateChanged(IntakeInfoViewModel vm) {
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
  void dispose() {
    print('💀 dispose IntakeInfoPage');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(intakeInfoViewModelProvider(widget.patientId));
    print(
      '🎨 build — vm.loadCommand.running=${vm.loadCommand.running}, vm.hasData=${vm.hasData}',
    );

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
                  print(
                    '🔄 ListenableBuilder rebuilt — running=${vm.loadCommand.running}, error=${vm.loadCommand.error}, errorMsg=${vm.errorMessage}',
                  );
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
