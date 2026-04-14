import 'package:flutter/material.dart';

import '../../view_models/intake_info_view_model.dart';
import 'ingress_type_section.dart';
import 'origin_section.dart';
import 'programs_section.dart';
import 'service_reason_section.dart';

class IntakeInfoContent extends StatefulWidget {
  const IntakeInfoContent({super.key, required this.viewModel});

  final IntakeInfoViewModel viewModel;

  @override
  State<IntakeInfoContent> createState() => _IntakeInfoContentState();
}

class _IntakeInfoContentState extends State<IntakeInfoContent> {
  late final TextEditingController _originNameController;
  late final TextEditingController _originContactController;
  late final TextEditingController _serviceReasonController;

  IntakeInfoViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _originNameController = TextEditingController(text: vm.originName)
      ..addListener(() => vm.updateOriginName(_originNameController.text));
    _originContactController = TextEditingController(
      text: vm.originContact,
    )..addListener(() => vm.updateOriginContact(_originContactController.text));
    _serviceReasonController = TextEditingController(
      text: vm.serviceReason,
    )..addListener(() => vm.updateServiceReason(_serviceReasonController.text));

    vm.addListener(_syncControllers);
  }

  void _syncControllers() {
    if (_originNameController.text != vm.originName) {
      _originNameController.text = vm.originName;
    }
    if (_originContactController.text != vm.originContact) {
      _originContactController.text = vm.originContact;
    }
    if (_serviceReasonController.text != vm.serviceReason) {
      _serviceReasonController.text = vm.serviceReason;
    }
  }

  @override
  void dispose() {
    vm.removeListener(_syncControllers);
    _originNameController.dispose();
    _originContactController.dispose();
    _serviceReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  return IngressTypeSection(
                    lookups: vm.ingressTypeLookup,
                    selectedId: vm.ingressTypeId,
                    onSelected: vm.updateIngressType,
                  );
                },
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              OriginSection(
                isWide: isWide,
                originNameController: _originNameController,
                originContactController: _originContactController,
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              ServiceReasonSection(controller: _serviceReasonController),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  final selectedIds = vm.linkedPrograms
                      .map((p) => p.programId)
                      .toSet();
                  return ProgramsSection(
                    lookups: vm.socialProgramsLookup,
                    selectedProgramIds: selectedIds,
                    onToggle: vm.toggleProgram,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
