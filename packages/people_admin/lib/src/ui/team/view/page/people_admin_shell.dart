import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/register_worker_intent.dart';
import '../../../../domain/models/system_role.dart';
import '../../constants/team_l10n.dart';
import '../../di/team_providers.dart';
import '../../view_models/add_worker_form_state.dart';
import '../../view_models/people_list_view_model.dart';
import '../../view_models/person_detail_view_model.dart';
import '../components/add_worker_modal.dart';

/// Master-Detail shell for the People Admin module.
///
/// Uses [ConsumerWidget] with [ref.read] (not watch) to inject
/// ViewModels into child widgets. Reactivity is handled via
/// [ListenableBuilder] at the leaf level (Selectors & Connectors).
class PeopleAdminShell extends ConsumerStatefulWidget {
  const PeopleAdminShell({super.key});

  @override
  ConsumerState<PeopleAdminShell> createState() => _PeopleAdminShellState();
}

class _PeopleAdminShellState extends ConsumerState<PeopleAdminShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(peopleListViewModelProvider).loadCommand.execute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listVm = ref.read(peopleListViewModelProvider);
    final detailVm = ref.read(personDetailViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(TeamL10n.pageTitle),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: PeopleMasterPanel(
                  viewModel: listVm,
                  onSelectPerson: (id) =>
                      detailVm.loadPersonCommand.execute(id),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: PersonDetailPanel(viewModel: detailVm),
              ),
            ],
          ),
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddWorkerModal(context, listVm),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                TeamL10n.addWorker,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAddWorkerModal(BuildContext context, PeopleListViewModel listVm) {
  final formState = AddWorkerFormState();

  showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => AddWorkerModal(
      formState: formState,
      canSubmit: () => formState.isValid,
      onRegister: () async {
        final intent = RegisterWorkerIntent(
          fullName: formState.fullName.text.trim(),
          birthDate: formState.birthDate.text.trim(),
          email: formState.email.text.trim(),
          role: formState.selectedRole.value!,
          cpf: formState.cpf.text.trim().isEmpty
              ? null
              : formState.cpf.text.trim(),
          initialPassword: formState.initialPassword.text.trim().isEmpty
              ? null
              : formState.initialPassword.text.trim(),
        );
        await listVm.registerCommand.execute(intent);
      },
    ),
  ).then((_) => formState.dispose());
}

/// Master panel — search bar + paginated people list.
///
/// Uses [ListenableBuilder] only around the list area, keeping
/// the search bar static (fires commands via Connector).
class PeopleMasterPanel extends StatelessWidget {
  const PeopleMasterPanel({
    super.key,
    required this.viewModel,
    required this.onSelectPerson,
  });

  final PeopleListViewModel viewModel;
  final void Function(String personId) onSelectPerson;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: TeamL10n.searchHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => viewModel.searchCommand.execute(text),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              if (viewModel.searchCommand.running && viewModel.people.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.people.isEmpty) {
                return const Center(
                  child: Text(TeamL10n.emptyState),
                );
              }

              return ListView.separated(
                itemCount: viewModel.people.length + (viewModel.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == viewModel.people.length) {
                    viewModel.loadMoreCommand.execute();
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final person = viewModel.people[index];
                  return PersonListTile(
                    fullName: person.fullName,
                    cpf: person.cpf,
                    active: person.active,
                    onTap: () => onSelectPerson(person.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single person row in the master list.
///
/// Receives only Selectors (data) — never the ViewModel.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.fullName,
    required this.active,
    required this.onTap,
    this.cpf,
  });

  final String fullName;
  final String? cpf;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: active ? AppColors.primary : AppColors.inputLine,
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.background),
        ),
      ),
      title: Text(
        fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: cpf != null ? Text(cpf!) : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          active ? TeamL10n.statusActive : TeamL10n.statusInactive,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.danger,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Detail panel — shows selected person info and roles.
///
/// Reactivity scoped: [ListenableBuilder] wraps only the content
/// that changes when a person is loaded.
class PersonDetailPanel extends StatelessWidget {
  const PersonDetailPanel({super.key, required this.viewModel});

  final PersonDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final person = viewModel.person;
        if (person == null) {
          return const Center(
            child: Text(
              'Selecione um membro da equipe',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonHeaderSection(
                fullName: person.fullName,
                email: person.email,
                cpf: person.cpf,
                active: person.active,
              ),
              const SizedBox(height: 24),
              PersonActionsBar(
                active: person.active,
                onToggleStatus: viewModel.toggleStatusPersonCommand.execute,
                onResetPassword: viewModel.requestPasswordResetCommand.execute,
              ),
              const SizedBox(height: 24),
              PersonRolesSection(
                roles: viewModel.roles,
                onAssignRole: (system, role) =>
                    viewModel.assignRoleCommand.execute((
                  system: system,
                  role: role,
                )),
                onToggleRole: (roleId, activate) =>
                    viewModel.toggleRoleCommand.execute((
                  roleId: roleId,
                  activate: activate,
                )),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Header section — person name, email, status badge.
///
/// Pure Selector widget — receives only the data it needs.
class PersonHeaderSection extends StatelessWidget {
  const PersonHeaderSection({
    super.key,
    required this.fullName,
    required this.active,
    this.email,
    this.cpf,
  });

  final String fullName;
  final String? email;
  final String? cpf;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                active ? TeamL10n.statusActive : TeamL10n.statusInactive,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
        if (email != null) ...[
          const SizedBox(height: 8),
          Text(email!, style: const TextStyle(color: AppColors.textMuted)),
        ],
        if (cpf != null) ...[
          const SizedBox(height: 4),
          Text('CPF: $cpf',
              style: const TextStyle(color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

/// Action bar — toggle status + reset password buttons.
///
/// Pure Connector widget — receives only callbacks.
class PersonActionsBar extends StatelessWidget {
  const PersonActionsBar({
    super.key,
    required this.active,
    required this.onToggleStatus,
    required this.onResetPassword,
  });

  final bool active;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: onToggleStatus,
          icon: Icon(active ? Icons.block : Icons.check_circle_outline),
          label: Text(
            active ? TeamL10n.actionDeactivate : TeamL10n.actionReactivate,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onResetPassword,
          icon: const Icon(Icons.lock_reset),
          label: const Text(TeamL10n.actionResetPassword),
        ),
      ],
    );
  }
}

/// Roles section — list of assigned roles with toggle.
///
/// Receives Selectors (role data) + Connectors (assign/toggle callbacks).
class PersonRolesSection extends StatelessWidget {
  const PersonRolesSection({
    super.key,
    required this.roles,
    required this.onAssignRole,
    required this.onToggleRole,
  });

  final List<SystemRole> roles;
  final void Function(String system, String role) onAssignRole;
  final void Function(String roleId, bool activate) onToggleRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Permissoes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (roles.isEmpty)
          const Text(
            'Nenhuma permissao atribuida.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ...roles.map((role) {
          return SwitchListTile(
            title: Text('${role.system} / ${role.role}'),
            value: role.active,
            onChanged: (value) => onToggleRole(role.id, value),
          );
        }),
      ],
    );
  }
}
