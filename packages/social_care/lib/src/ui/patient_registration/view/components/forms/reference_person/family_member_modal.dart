import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

import 'family_composition_form_state.dart';

/// Modal dialog for adding or editing a family member.
///
/// Design: dark blue (#172D48) background, 2-column layout (1fr + 260px),
/// collapses to single column on mobile. Matches the Figma specification.
class FamilyMemberModal extends StatefulWidget {
  final FamilyMemberEntry entry;
  final FamilyMemberSnapshot? existingMember;
  final void Function(FamilyMemberSnapshot snapshot) onSave;
  final VoidCallback? onCaregiverConflict;
  final bool hasPrimaryCaregiver;
  final List<LookupItem> parentescoLookup;

  const FamilyMemberModal({
    super.key,
    required this.entry,
    this.existingMember,
    required this.onSave,
    this.onCaregiverConflict,
    this.hasPrimaryCaregiver = false,
    this.parentescoLookup = const [],
  });

  @override
  State<FamilyMemberModal> createState() => _FamilyMemberModalState();
}

class _FamilyMemberModalState extends State<FamilyMemberModal> {
  FamilyMemberEntry get _entry => widget.entry;
  bool _showErrors = false;

  static const _deepBlue = AppColors.backgroundDark;
  static const _offWhite = AppColors.textOnDark;
  static const _red = AppColors.danger;

  List<(String, String)> get _parentescoOptions {
    if (widget.parentescoLookup.isEmpty) return const [];
    return widget.parentescoLookup
        .where((item) => item.codigo != 'PESSOA_REFERENCIA')
        .map((item) => (item.codigo, '${item.codigo} - ${item.descricao}'))
        .toList();
  }

  static const _docOptions = ['CN', 'RG', 'CTPS', 'CPF', 'TE', 'CNS'];

  void _handleSave() {
    if (!_entry.isValid) {
      setState(() => _showErrors = true);
      return;
    }

    final wantsCaregiver = _entry.isCaregiver.value == true;
    final isEditingSameCaregiver =
        widget.existingMember?.isCaregiver == true;

    // Prevent multiple primary caregivers — delegate to parent
    if (wantsCaregiver && widget.hasPrimaryCaregiver && !isEditingSameCaregiver) {
      widget.onCaregiverConflict?.call();
      return;
    }

    widget.onSave(FamilyMemberSnapshot(
      name: _entry.name.text.trim(),
      birthDate: _entry.dateParsed!,
      sex: _entry.sex.value!,
      relationshipCode: _entry.relationship.value!,
      hasDisability: _entry.hasDisability.value ?? false,
      isResiding: _entry.isResiding.value ?? true,
      isCaregiver: _entry.isCaregiver.value ?? false,
      requiredDocuments: {..._entry.requiredDocuments.value},
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMember != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 788),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _deepBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(-9, 9), blurRadius: 9),
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(-18, 18), blurRadius: 18),
                BoxShadow(color: Colors.black.withValues(alpha: 0.16), offset: const Offset(-37, 37), blurRadius: 37),
                BoxShadow(color: Colors.black.withValues(alpha: 0.24), offset: const Offset(-75, 75), blurRadius: 75),
                BoxShadow(color: Colors.black.withValues(alpha: 0.48), offset: const Offset(-150, 150), blurRadius: 150),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isEditing),
                    const SizedBox(height: 28),
                    _buildBody(),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.textOnDark.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            isEditing
                ? ReferencePersonLn10.memberModalEditTitle
                : ReferencePersonLn10.memberModalTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _offWhite,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(Icons.close, color: _red, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLeftColumn()),
              const SizedBox(width: 40),
              SizedBox(width: 260, child: _buildRightColumn()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeftColumn(),
            const SizedBox(height: 28),
            _buildRightColumn(),
          ],
        );
      },
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ReferencePersonLn10.memberNameLabel, required: true),
        _buildTextInput(
          controller: _entry.name,
          placeholder: ReferencePersonLn10.memberNamePlaceholder,
          errorText: _showErrors ? _entry.nameError : null,
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberBirthDateLabel, required: true),
        _buildTextInput(
          controller: _entry.birthDate,
          placeholder: ReferencePersonLn10.birthDatePlaceholder,
          errorText: _showErrors ? _entry.birthDateError : null,
          formatters: AppMasks.date,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberSexLabel, required: true),
        _buildRadioGroup<String>(
          notifier: _entry.sex,
          options: [('masculino', ReferencePersonLn10.genderOptionMale), ('feminino', ReferencePersonLn10.genderOptionFemale), ('outro', ReferencePersonLn10.genderOptionOther)],
          errorText: _showErrors ? _entry.sexError : null,
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberPcdLabel, required: true),
        _buildRadioGroup<bool>(
          notifier: _entry.hasDisability,
          options: [(true, ReferencePersonLn10.radioYes), (false, ReferencePersonLn10.radioNo)],
          errorText: _showErrors ? _entry.hasDisabilityError : null,
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberResidingLabel),
        _buildRadioGroup<bool>(
          notifier: _entry.isResiding,
          options: [(true, ReferencePersonLn10.radioYes), (false, ReferencePersonLn10.radioNo)],
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberCaregiverLabel),
        _buildRadioGroup<bool>(
          notifier: _entry.isCaregiver,
          options: [(true, ReferencePersonLn10.radioYes), (false, ReferencePersonLn10.radioNo)],
        ),
        const SizedBox(height: 28),
        _buildLabel(ReferencePersonLn10.memberDocsLabel),
        _buildDocCheckboxes(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(ReferencePersonLn10.memberRelationshipLabel, required: true),
        const SizedBox(height: 8),
        if (_parentescoOptions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              ReferencePersonLn10.loadingRelationship,
              style: TextStyle(
                color: _offWhite.withValues(alpha: 0.6),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ValueListenableBuilder<String?>(
            valueListenable: _entry.relationship,
            builder: (context, selected, _) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _offWhite),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (code, label) in _parentescoOptions)
                      InkWell(
                        onTap: () => _entry.relationship.value = code,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: selected == code
                              ? _offWhite.withValues(alpha: 0.1)
                              : Colors.transparent,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: _offWhite,
                              fontSize: 14,
                              fontWeight: selected == code ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        if (_showErrors && _entry.relationshipError != null) ...[
          const SizedBox(height: 4),
          Text(
            _entry.relationshipError!,
            style: const TextStyle(color: _red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _handleSave,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: _deepBlue,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: _offWhite.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 4,
                  offset: const Offset(-1, -1),
                ),
                BoxShadow(
                  color: _offWhite.withValues(alpha: 0.18),
                  blurRadius: 5,
                  spreadRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Text(
              ReferencePersonLn10.memberModalSave,
              style: TextStyle(
                color: _offWhite,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared building blocks ──

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _offWhite,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: _red, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String placeholder,
    String? errorText,
    List<dynamic>? formatters,
    TextInputType? keyboardType,
  }) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters?.cast(),
          style: const TextStyle(
            color: _offWhite,
            fontSize: 15,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: _offWhite.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _offWhite.withValues(alpha: 0.35)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _offWhite),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: _red, fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildRadioGroup<T>({
    required ValueNotifier<T?> notifier,
    required List<(T, String)> options,
    String? errorText,
  }) {
    return ValueListenableBuilder<T?>(
      valueListenable: notifier,
      builder: (context, selected, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                for (final (value, label) in options)
                  GestureDetector(
                    onTap: () => notifier.value = value,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AcdgRadioButton<T>(
                            value: value,
                            groupValue: selected,
                            onChanged: (v) => notifier.value = v,
                            activeColor: AppColors.surface,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: TextStyle(
                              color: _offWhite.withValues(alpha: 0.8),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(errorText, style: const TextStyle(color: _red, fontSize: 12)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDocCheckboxes() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _entry.requiredDocuments,
      builder: (context, selected, _) {
        return Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            for (final doc in _docOptions)
              GestureDetector(
                onTap: () {
                  final current = {...selected};
                  if (current.contains(doc)) {
                    current.remove(doc);
                  } else {
                    current.add(doc);
                  }
                  _entry.requiredDocuments.value = current;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcdgCheckbox(
                        value: selected.contains(doc),
                        onChanged: (_) {
                          final current = {...selected};
                          if (current.contains(doc)) {
                            current.remove(doc);
                          } else {
                            current.add(doc);
                          }
                          _entry.requiredDocuments.value = current;
                        },
                        activeColor: AppColors.surface,
                        checkColor: AppColors.backgroundDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        doc,
                        style: TextStyle(
                          color: selected.contains(doc)
                              ? _offWhite
                              : _offWhite.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
