import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import '../../constants/family_composition_ln10.dart';
import '../../models/add_member_result.dart';
import 'relationship_selection_list.dart';

/// Modal for adding or editing a family member.
/// Dark blue (#172D48) background, 2-column layout, matching Figma spec.
class AddMemberModal extends StatefulWidget {
  final List<LookupItem> parentescoLookup;
  final void Function(AddMemberResult result) onSave;

  /// If non-null, modal opens in edit mode with pre-filled data.
  final AddMemberResult? existing;

  const AddMemberModal({
    super.key,
    required this.parentescoLookup,
    required this.onSave,
    this.existing,
  });

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal> {
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  String? _sex;
  String? _relationship;
  bool? _residing;
  bool? _pcd;
  bool _caregiver = false;
  final _docs = <String>{};
  bool _showErrors = false;

  static const _docOptions = ['CN', 'RG', 'CTPS', 'CPF', 'TE'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      final d = e.birthDate;
      _birthDate.text =
          '${d.day.toString().padLeft(2, '0')}${d.month.toString().padLeft(2, '0')}${d.year}';
      _sex = e.sex == FamilyCompositionLn10.sexMale
          ? 'masculino'
          : e.sex == FamilyCompositionLn10.sexFemale
              ? 'feminino'
              : 'outro';
      _relationship = e.relationshipCode;
      _residing = e.residesWithPatient;
      _pcd = e.hasDisability;
      _caregiver = e.isPrimaryCaregiver;
      _docs.addAll(e.requiredDocuments);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  // ── Validation ──

  String? get _nameError {
    if (_name.text.trim().isEmpty) return FamilyCompositionLn10.errorRequired;
    if (_name.text.trim().length < 3) return FamilyCompositionLn10.errorMinChars3;
    return null;
  }

  String? get _birthDateError {
    final digits = _birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return FamilyCompositionLn10.errorBirthDate;
    if (digits.length != 8) return FamilyCompositionLn10.errorDateIncomplete;
    if (_parsedDate == null) return FamilyCompositionLn10.errorDateInvalid;
    return null;
  }

  DateTime? get _parsedDate {
    final digits = _birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String? get _sexError => _sex == null ? FamilyCompositionLn10.errorSelectSex : null;
  String? get _relationshipError =>
      _relationship == null ? FamilyCompositionLn10.errorSelectRelationship : null;
  String? get _residingError =>
      _residing == null ? FamilyCompositionLn10.errorSelectResiding : null;
  String? get _pcdError =>
      _pcd == null ? FamilyCompositionLn10.errorSelectPcd : null;

  bool get _isValid =>
      _nameError == null &&
      _birthDateError == null &&
      _sexError == null &&
      _relationshipError == null &&
      _residingError == null &&
      _pcdError == null;

  void _handleSave() {
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }

    final sexLabel = switch (_sex) {
      'masculino' => FamilyCompositionLn10.sexMale,
      'feminino' => FamilyCompositionLn10.sexFemale,
      _ => FamilyCompositionLn10.sexOther,
    };

    widget.onSave(AddMemberResult(
      name: _name.text.trim(),
      birthDate: _parsedDate!,
      sex: sexLabel,
      relationshipCode: _relationship!,
      residesWithPatient: _residing!,
      hasDisability: _pcd!,
      isPrimaryCaregiver: _caregiver,
      requiredDocuments: {..._docs},
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: AppColors.buttonShadow, offset: Offset(-75, 75), blurRadius: 75),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info note
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.07),
                        border: Border.all(color: AppColors.background.withValues(alpha: 0.14)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text('ℹ',
                              style: TextStyle(fontSize: 12, color: AppColors.background.withValues(alpha: 0.55))),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              FamilyCompositionLn10.modalNote,
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 10,
                                color: AppColors.background.withValues(alpha: 0.55),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(Icons.close, color: AppColors.danger, size: 18),
                        ),
                      ),
                    ),
                    // Body — 2 columns
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        final relationshipList = RelationshipSelectionList(
                          parentescoLookup: widget.parentescoLookup,
                          selectedRelationship: _relationship,
                          onChanged: (val) => setState(() => _relationship = val),
                          error: _relationshipError,
                          showErrors: _showErrors,
                          enabled: !isEditing,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildLeftColumn(isEditing: isEditing)),
                              const SizedBox(width: 40),
                              SizedBox(width: 240, child: relationshipList),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(isEditing: isEditing),
                            const SizedBox(height: 22),
                            relationshipList,
                          ],
                        );
                      },
                    ),
                    // Footer
                    const SizedBox(height: 16),
                    Divider(color: AppColors.background.withValues(alpha: 0.1)),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _handleSave,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.background.withValues(alpha: 0.25)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.background.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              FamilyCompositionLn10.modalSave,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn({required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(FamilyCompositionLn10.fieldName, required: true,
            error: _showErrors ? _nameError : null,
            child: _textInput(_name, FamilyCompositionLn10.fieldNamePlaceholder,
                enabled: !isEditing)),
        _field(FamilyCompositionLn10.fieldBirthDate, required: true,
            error: _showErrors ? _birthDateError : null,
            child: _textInput(_birthDate, FamilyCompositionLn10.fieldBirthDatePlaceholder,
                formatters: AppMasks.date, keyboardType: TextInputType.number,
                enabled: !isEditing)),
        _field(FamilyCompositionLn10.fieldSex, required: true,
            error: _showErrors ? _sexError : null,
            child: _radioGroup(['masculino', 'feminino', 'outro'],
                [FamilyCompositionLn10.sexMale, FamilyCompositionLn10.sexFemale, FamilyCompositionLn10.sexOther],
                _sex, (v) => setState(() => _sex = v),
                enabled: !isEditing)),
        _field(FamilyCompositionLn10.fieldResiding, required: true,
            error: _showErrors ? _residingError : null,
            child: _radioGroup(['true', 'false'],
                [FamilyCompositionLn10.residesYes, FamilyCompositionLn10.residesNo],
                _residing?.toString(), (v) => setState(() => _residing = v == 'true'))),
        _field(FamilyCompositionLn10.fieldPcd, required: true,
            error: _showErrors ? _pcdError : null,
            child: _radioGroup(['true', 'false'],
                [FamilyCompositionLn10.residesYes, FamilyCompositionLn10.residesNo],
                _pcd?.toString(), (v) => setState(() => _pcd = v == 'true'))),
        _field(FamilyCompositionLn10.fieldCaregiver,
            child: _radioGroup(['true', 'false'],
                [FamilyCompositionLn10.residesYes, FamilyCompositionLn10.residesNo],
                _caregiver.toString(), (v) => setState(() => _caregiver = v == 'true'))),
        _field(FamilyCompositionLn10.fieldDocuments, child: _docCheckboxes()),
      ],
    );
  }



  // ── Building blocks ──

  Widget _field(String label, {bool required = false, String? error, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.background,
              ),
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger, fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          child,
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, color: AppColors.danger)),
          ],
        ],
      ),
    );
  }

  Widget _textInput(TextEditingController controller, String placeholder,
      {List<dynamic>? formatters, TextInputType? keyboardType, bool enabled = true}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters?.cast(),
      readOnly: !enabled,
      style: const TextStyle(
        color: AppColors.background,
        fontSize: 14,
        fontFamily: 'Playfair Display',
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: AppColors.background.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.background.withValues(alpha: 0.3))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.background)),
        isDense: true,
        contentPadding: const EdgeInsets.only(bottom: 6),
      ),
    );
  }

  Widget _radioGroup(List<String> values, List<String> labels, String? selected,
      void Function(String) onChanged, {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        for (var i = 0; i < values.length; i++)
          GestureDetector(
            onTap: enabled ? () => onChanged(values[i]) : null,
            child: MouseRegion(
              cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background.withValues(alpha: selected == values[i] ? 1.0 : 0.4),
                        width: 2,
                      ),
                      color: selected == values[i] ? AppColors.background : Colors.transparent,
                    ),
                    child: selected == values[i]
                        ? Center(
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.backgroundDark),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    );
  }

  Widget _docCheckboxes() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final doc in _docOptions)
          GestureDetector(
            onTap: () => setState(() {
              if (_docs.contains(doc)) {
                _docs.remove(doc);
              } else {
                _docs.add(doc);
              }
            }),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.background.withValues(alpha: _docs.contains(doc) ? 1.0 : 0.3),
                        width: 1.5,
                      ),
                      color: _docs.contains(doc) ? AppColors.background : Colors.transparent,
                    ),
                    child: _docs.contains(doc)
                        ? const Center(
                            child: Text('\u2713',
                                style: TextStyle(color: AppColors.backgroundDark, fontSize: 9, fontWeight: FontWeight.w700)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    doc,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      color: _docs.contains(doc) ? AppColors.background : AppColors.background.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
