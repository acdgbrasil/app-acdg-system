import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/educational_status_l10n.dart';
import '../../di/educational_status_providers.dart';
import '../components/educational_status_content.dart';

class EducationalStatusPage extends ConsumerStatefulWidget {
  const EducationalStatusPage({super.key, required this.patientId});
  final String patientId;
  @override
  ConsumerState<EducationalStatusPage> createState() => _EducationalStatusPageState();
}

class _EducationalStatusPageState extends ConsumerState<EducationalStatusPage> {
  @override
  void initState() { super.initState(); ref.read(educationalStatusViewModelProvider(widget.patientId)).loadCommand.execute(); }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(educationalStatusViewModelProvider(widget.patientId));
    return Scaffold(body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), child: Row(children: [
        Column(children: [Container(height: 2, width: 24, color: AppColors.textPrimary), const SizedBox(height: 5), Container(height: 2, width: 24, color: AppColors.textPrimary), const SizedBox(height: 5), Container(height: 2, width: 24, color: AppColors.textPrimary)]),
        const SizedBox(width: 24), Text(EducationalStatusL10n.navFamilies, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.55))),
        const SizedBox(width: 24), const Text(EducationalStatusL10n.navRegistration, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary, decoration: TextDecoration.underline, decorationColor: AppColors.textPrimary)),
      ])),
      ListenableBuilder(listenable: vm, builder: (context, _) => Padding(padding: const EdgeInsets.fromLTRB(48, 4, 48, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(EducationalStatusL10n.pageTitle, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700, fontSize: 38, letterSpacing: -1, color: AppColors.textPrimary)),
        if (vm.patientName.isNotEmpty) ...[const SizedBox(height: 4), Text(vm.patientName, style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textPrimary.withValues(alpha: 0.6)))],
      ]))),
      Expanded(child: ListenableBuilder(listenable: vm.loadCommand, builder: (context, _) {
        if (vm.loadCommand.running) return const Center(child: CircularProgressIndicator());
        if (vm.errorMessage != null && !vm.hasData) return Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)));
        return EducationalStatusContent(viewModel: vm);
      })),
      ListenableBuilder(listenable: vm, builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.inputLine))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(onPressed: () { if (context.canPop()) context.pop(); else context.go('/social-care'); }, style: TextButton.styleFrom(foregroundColor: AppColors.danger, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.close, size: 16), SizedBox(width: 7), Text(EducationalStatusL10n.btnCancel, style: TextStyle(fontFamily: 'Playfair Display', fontStyle: FontStyle.italic, fontSize: 14))])),
          FilledButton(onPressed: vm.canSave ? () => vm.saveCommand.execute() : null, style: FilledButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Text(EducationalStatusL10n.btnSave, style: TextStyle(fontFamily: 'Playfair Display', fontStyle: FontStyle.italic, fontSize: 14, color: AppColors.background)), SizedBox(width: 7), Icon(Icons.check, size: 16, color: AppColors.background)])),
        ]),
      )),
    ])));
  }
}
