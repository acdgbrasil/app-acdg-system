import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/intake_info_l10n.dart';
import '../../view_models/intake_info_view_model.dart';

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
    _originContactController = TextEditingController(text: vm.originContact)
      ..addListener(
        () => vm.updateOriginContact(_originContactController.text),
      );
    _serviceReasonController = TextEditingController(text: vm.serviceReason)
      ..addListener(
        () => vm.updateServiceReason(_serviceReasonController.text),
      );

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
              _buildIngressTypeSection(isWide),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              _buildOriginSection(isWide),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              _buildServiceReasonSection(isWide),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 24),
              _buildProgramsSection(),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIngressTypeSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionIngressType,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final lookups = vm.ingressTypeLookup;
            if (lookups.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lookups.map((item) {
                final isSelected = vm.ingressTypeId == item.id;
                return ChoiceChip(
                  label: Text(item.descricao),
                  selected: isSelected,
                  onSelected: (_) => vm.updateIngressType(item.id),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOriginSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionOrigin,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originNameController,
                  decoration: const InputDecoration(
                    labelText: IntakeInfoL10n.originNameLabel,
                    hintText: IntakeInfoL10n.originNameHint,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: _originContactController,
                  decoration: const InputDecoration(
                    labelText: IntakeInfoL10n.originContactLabel,
                    hintText: IntakeInfoL10n.originContactHint,
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              TextField(
                controller: _originNameController,
                decoration: const InputDecoration(
                  labelText: IntakeInfoL10n.originNameLabel,
                  hintText: IntakeInfoL10n.originNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _originContactController,
                decoration: const InputDecoration(
                  labelText: IntakeInfoL10n.originContactLabel,
                  hintText: IntakeInfoL10n.originContactHint,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildServiceReasonSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionReason,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _serviceReasonController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: IntakeInfoL10n.serviceReasonLabel,
            hintText: IntakeInfoL10n.serviceReasonHint,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          IntakeInfoL10n.sectionPrograms,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final lookups = vm.socialProgramsLookup;
            if (lookups.isEmpty) {
              return const SizedBox.shrink();
            }
            final selectedIds = vm.linkedPrograms
                .map((p) => p.programId)
                .toSet();
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: lookups.map((item) {
                return FilterChip(
                  label: Text(item.descricao),
                  selected: selectedIds.contains(item.id),
                  onSelected: (_) => vm.toggleProgram(item.id),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    color: selectedIds.contains(item.id)
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
