import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../constants/social_identity_l10n.dart';
import '../../view_models/social_identity_view_model.dart';

class SocialIdentityContent extends StatefulWidget {
  const SocialIdentityContent({super.key, required this.viewModel});
  final SocialIdentityViewModel viewModel;

  @override
  State<SocialIdentityContent> createState() => _SocialIdentityContentState();
}

class _SocialIdentityContentState extends State<SocialIdentityContent> {
  late final TextEditingController _otherController;
  SocialIdentityViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: vm.otherDescription)
      ..addListener(() => vm.updateOtherDescription(_otherController.text));
    vm.addListener(_sync);
  }

  void _sync() {
    if (_otherController.text != vm.otherDescription) _otherController.text = vm.otherDescription;
  }

  @override
  void dispose() { vm.removeListener(_sync); _otherController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: ListenableBuilder(listenable: vm, builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(SocialIdentityL10n.sectionIdentity, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: vm.typeId != null && vm.identityTypeLookup.any((i) => i.id == vm.typeId) ? vm.typeId : null,
            decoration: const InputDecoration(labelText: SocialIdentityL10n.typeLabel),
            items: vm.identityTypeLookup.map((i) => DropdownMenuItem(value: i.id, child: Text(i.descricao))).toList(),
            onChanged: (v) { if (v != null) vm.updateTypeId(v); },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _otherController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(labelText: SocialIdentityL10n.otherDescriptionLabel, hintText: SocialIdentityL10n.otherDescriptionHint, alignLabelWithHint: true),
          ),
          const SizedBox(height: 40),
        ],
      )),
    );
  }
}
