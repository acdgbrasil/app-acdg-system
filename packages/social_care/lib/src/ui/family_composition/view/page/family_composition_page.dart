import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/family_composition_providers.dart';
import '../../models/add_member_result.dart';
import '../../models/family_member_model.dart';
import '../../view_models/family_composition_view_model.dart';
import '../components/add_member_modal.dart';
import '../components/confirm_caregiver_dialog.dart';
import '../components/confirm_remove_dialog.dart';
import '../components/family_composition_action_bar.dart';
import '../components/family_composition_content.dart';
import '../components/family_composition_header.dart';
import '../components/family_composition_nav_bar.dart';

/// Standalone page for the Family Composition "ficha".
///
/// Thin UI shell — all business logic lives in [FamilyCompositionViewModel].
/// Receives [patientId] via route param and reads the VM from Riverpod.
///
/// Follows Selectors & Connectors: [ListenableBuilder] wraps only the
/// subtrees that actually change (Content + ActionBar), leaving NavBar
/// and Header static.
class FamilyCompositionPage extends ConsumerStatefulWidget {
  const FamilyCompositionPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<FamilyCompositionPage> createState() =>
      _FamilyCompositionPageState();
}

class _FamilyCompositionPageState extends ConsumerState<FamilyCompositionPage> {
  late final FamilyCompositionViewModel _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = ref.read(familyCompositionViewModelProvider(widget.patientId));
      _vm.loadPatientCommand.execute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(familyCompositionViewModelProvider(widget.patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: vm.loadPatientCommand,
          builder: (context, _) {
            if (vm.loadPatientCommand.running) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (vm.loadPatientCommand.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao carregar dados do paciente',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => vm.loadPatientCommand.execute(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                const FamilyCompositionNavBar(),
                FamilyCompositionHeader(onAddMember: () => _showAddModal(vm)),
                Expanded(
                  child: ListenableBuilder(
                    listenable: vm,
                    builder: (context, _) => FamilyCompositionContent(
                      viewModel: vm,
                      onEdit: (m) => _showAddModal(vm, existing: m),
                      onRemove: (m) => _showRemoveDialog(vm, m),
                      onToggleCaregiver: (m) => _showCaregiverDialog(vm, m),
                      onAddMember: () => _showAddModal(vm),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: vm,
                  builder: (context, _) => FamilyCompositionActionBar(
                    canSave: vm.canSave,
                    onCancel: () => context.go('/social-care'),
                    onSave: () async {
                      await vm.saveChangesCommand.execute();
                      if (context.mounted && vm.saveChangesCommand.completed) {
                        context.go('/social-care');
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Dialog triggers ──

  void _showAddModal(
    FamilyCompositionViewModel vm, {
    FamilyMemberModel? existing,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.backgroundDark.withValues(alpha: 0.55),
      builder: (_) => AddMemberModal(
        parentescoLookup: vm.parentescoLookup,
        existing: existing != null
            ? AddMemberResult(
                name: existing.displayName,
                birthDate: existing.birthDate,
                sex: existing.sex,
                relationshipCode: existing.relationshipCode,
                residesWithPatient: existing.residesWithPatient,
                hasDisability: existing.hasDisability,
                isPrimaryCaregiver: existing.isPrimaryCaregiver,
                requiredDocuments: existing.requiredDocuments,
              )
            : null,
        onSave: (r) => vm.handleModalSave(r, existing: existing),
      ),
    );
  }

  void _showRemoveDialog(FamilyCompositionViewModel vm, FamilyMemberModel m) {
    if (m.isReferencePerson) return;
    ConfirmRemoveDialog.show(
      context,
      member: m,
      onConfirm: () => vm.handleRemove(m),
    );
  }

  void _showCaregiverDialog(
    FamilyCompositionViewModel vm,
    FamilyMemberModel m,
  ) {
    if (m.isReferencePerson) return;
    if (vm.needsCaregiverConfirmation(m)) {
      ConfirmCaregiverDialog.show(
        context,
        currentCaregiver: vm.currentCaregiver!,
        newCandidate: m,
        onConfirm: () => vm.handleCaregiverToggle(m),
      );
    } else {
      vm.handleCaregiverToggle(m);
    }
  }
}
