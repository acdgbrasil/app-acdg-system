import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/home_providers.dart';
import '../components/detail_panel.dart';
import '../components/family_list.dart';
import '../components/home_top_bar.dart';
import '../components/inputs/search_input.dart';
import '../components/new_registration_fab.dart';

class SocialCareHomePage extends ConsumerStatefulWidget {
  final Widget? syncIndicator;

  const SocialCareHomePage({super.key, this.syncIndicator});

  @override
  ConsumerState<SocialCareHomePage> createState() => _SocialCareHomePageState();
}

class _SocialCareHomePageState extends ConsumerState<SocialCareHomePage> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider).load.execute();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(homeViewModelProvider).closePanel();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                ListenableBuilder(
                  listenable: viewModel.homeFormState.families,
                  builder: (context, _) {
                    return HomeTopBar(
                      activeTab: viewModel.activeTab,
                      onTabChanged: (tab) {
                        if (tab == 'cadastro') {
                          context.go('/patient-registration');
                          return;
                        }
                        viewModel.setActiveTab(tab);
                      },
                      familyCount: viewModel.homeFormState.totalCount,
                      syncIndicator: widget.syncIndicator,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 32),
                    child: Column(
                      children: [
                        // Search
                        SearchInput(
                          controller: viewModel.homeFormState.searchQuery,
                          onChanged: viewModel.onSearchChanged,
                        ),
                        const SizedBox(height: 24),

                        // Family list
                        Expanded(
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              viewModel.homeFormState.families,
                              viewModel.detailPanelState.selectedPatientId,
                            ]),
                            builder: (context, _) {
                              return FamilyList(
                                families:
                                    viewModel.homeFormState.filteredFamilies,
                                selectedId: viewModel
                                    .detailPanelState
                                    .selectedPatientId
                                    .value,
                                onSelect: (id) => viewModel.select.execute(id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Detail panel overlay
            ListenableBuilder(
              listenable: Listenable.merge([
                viewModel.detailPanelState.panelVisible,
                viewModel.detailPanelState.panelView,
                viewModel.detailPanelState.patientDetail,
                viewModel.detailPanelState.fichas,
                viewModel.select,
              ]),
              builder: (context, _) {
                final panel = viewModel.detailPanelState;
                return DetailPanel(
                  visible: panel.panelVisible.value,
                  panelView: panel.panelView.value,
                  detail: panel.patientDetail.value,
                  fichas: panel.fichas.value,
                  isLoading: viewModel.select.running,
                  onClose: viewModel.closePanel,
                  onShowFichas: viewModel.showFichas,
                  onShowDados: viewModel.showDados,
                  onFichaTap: (ficha, patientId) {
                    if (ficha.name.contains('Composição familiar')) {
                      context.go('/family-composition/$patientId');
                    }
                  },
                );
              },
            ),

            // FAB
            NewRegistrationFab(
              onPressed: () => context.go('/patient-registration'),
            ),
          ],
        ),
      ),
    );
  }
}
