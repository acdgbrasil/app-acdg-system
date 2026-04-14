import 'package:flutter/material.dart';
import '../../view_models/socio_economic_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../view_models/socio_economic_view_model.dart';

import '../../../shared/components/acdg_toast.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../../../shared/components/assessment_action_bar.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../../../shared/components/assessment_header.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../../../shared/components/assessment_nav_bar.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../../constants/socio_economic_l10n.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../../di/socio_economic_providers.dart';
import '../../view_models/socio_economic_view_model.dart';
import '../components/socio_economic_content.dart';
import '../../view_models/socio_economic_view_model.dart';

class SocioEconomicPage extends ConsumerStatefulWidget {
  const SocioEconomicPage({super.key, required this.patientId});
  final String patientId;

  @override
  ConsumerState<SocioEconomicPage> createState() => _SocioEconomicPageState();
}

class _SocioEconomicPageState extends ConsumerState<SocioEconomicPage> {
  @override
  void initState() {
    super.initState();
    final vm = ref.read(socioEconomicViewModelProvider(widget.patientId));
    vm.loadCommand.execute();
    vm.saveCommand.addListener(() => _onSaveStateChanged(vm));
  }

  void _onSaveStateChanged(SocioEconomicViewModel vm) {
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
    final vm = ref.watch(socioEconomicViewModelProvider(widget.patientId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AssessmentNavBar(
              familiesLabel: SocioEconomicL10n.navFamilies,
              currentPageLabel: SocioEconomicL10n.navRegistration,
            ),
            ListenableBuilder(
              listenable: vm.loadCommand,
              builder: (context, _) => AssessmentHeader(
                title: SocioEconomicL10n.pageTitle,
                patientName: vm.formState.patientName,
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: vm.loadCommand,
                builder: (context, _) {
                  if (vm.loadCommand.running) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (vm.loadCommand.error) {
                    return const Center(
                      child: Text(SocioEconomicL10n.loadError),
                    );
                  }
                  return SocioEconomicContent(viewModel: vm);
                },
              ),
            ),
            ListenableBuilder(
              listenable: vm,
              builder: (context, _) => AssessmentActionBar(
                cancelLabel: SocioEconomicL10n.btnCancel,
                saveLabel: SocioEconomicL10n.btnSave,
                canSave: vm.formState.canSave,
                onSave: () => vm.saveCommand.execute(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
