import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atoms/acdg_checkbox.dart';
import '../atoms/acdg_dropdown.dart';
import '../atoms/acdg_radio_button.dart';
import '../atoms/acdg_text.dart';
import '../atoms/acdg_underline_input.dart';
import '../tokens/app_breakpoints.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

enum SelectionType { checkbox, radio }

class SelectionOption {
  final String value;
  final String label;
  const SelectionOption({required this.value, required this.label});
}

enum _AcdgFormFieldType {
  text,
  selection,
  textWithInlineSelection,
  checkboxSimple,
  checkboxWithInput,
  dropdown,
}

class AcdgFormField extends StatelessWidget {
  final String label;
  final bool inverted;
  final bool enabled;
  final bool readOnly;
  final _AcdgFormFieldType _type;

  // Variant 1: Text
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? underlineWidth;
  final String? initialValue;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  // Variant 2 & 3: Selection
  final List<SelectionOption>? options;
  final String? selectedValue;
  final SelectionType selectionType;
  final Axis direction;

  // Variant 4 & 5: Checkbox Simple/WithInput
  final bool? isChecked;
  final ValueChanged<bool?>? onCheckChanged;
  final String? inputPlaceholder;
  final TextEditingController? inputController;
  final ValueChanged<String>? onInputChanged;

  // Variant 6: Dropdown
  final List<DropdownMenuItem<dynamic>>? dropdownItems;
  final dynamic dropdownValue;
  final ValueChanged<dynamic>? onDropdownChanged;

  const AcdgFormField.text({
    super.key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.underlineWidth,
    this.initialValue,
    this.errorText,
    this.inputFormatters,
    this.inverted = false,
    this.enabled = true,
    this.readOnly = false,
  }) : _type = _AcdgFormFieldType.text,
       options = null,
       selectedValue = null,
       selectionType = SelectionType.checkbox,
       direction = Axis.horizontal,
       isChecked = null,
       onCheckChanged = null,
       inputPlaceholder = null,
       inputController = null,
       onInputChanged = null,
       dropdownItems = null,
       dropdownValue = null,
       onDropdownChanged = null;

  const AcdgFormField.selection({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    this.selectionType = SelectionType.checkbox,
    this.onChanged,
    this.direction = Axis.horizontal,
    this.inverted = false,
    this.enabled = true,
  }) : _type = _AcdgFormFieldType.selection,
       placeholder = null,
       controller = null,
       keyboardType = null,
       underlineWidth = null,
       initialValue = null,
       errorText = null,
       inputFormatters = null,
       readOnly = false,
       isChecked = null,
       onCheckChanged = null,
       inputPlaceholder = null,
       inputController = null,
       onInputChanged = null,
       dropdownItems = null,
       dropdownValue = null,
       onDropdownChanged = null;

  const AcdgFormField.textWithInlineSelection({
    super.key,
    required this.label,
    required this.placeholder,
    required List<SelectionOption> inlineOptions,
    required String? selectedInlineValue,
    this.controller,
    this.onChanged, // Text changed
    ValueChanged<String>? onInlineChanged,
    this.initialValue,
    this.errorText,
    this.inputFormatters,
    this.inverted = false,
    this.enabled = true,
  }) : _type = _AcdgFormFieldType.textWithInlineSelection,
       options = inlineOptions,
       selectedValue = selectedInlineValue,
       selectionType = SelectionType.checkbox,
       direction = Axis.horizontal,
       keyboardType = null,
       underlineWidth = null,
       readOnly = false,
       isChecked = null,
       onCheckChanged = null,
       inputPlaceholder = null,
       inputController = null,
       onInputChanged = onInlineChanged,
       dropdownItems = null,
       dropdownValue = null,
       onDropdownChanged = null;

  const AcdgFormField.checkboxSimple({
    super.key,
    required this.label,
    required this.isChecked,
    this.onCheckChanged,
    this.inverted = false,
    this.enabled = true,
  }) : _type = _AcdgFormFieldType.checkboxSimple,
       placeholder = null,
       controller = null,
       keyboardType = null,
       onChanged = null,
       underlineWidth = null,
       initialValue = null,
       errorText = null,
       inputFormatters = null,
       options = null,
       selectedValue = null,
       selectionType = SelectionType.checkbox,
       direction = Axis.horizontal,
       readOnly = false,
       inputPlaceholder = null,
       inputController = null,
       onInputChanged = null,
       dropdownItems = null,
       dropdownValue = null,
       onDropdownChanged = null;

  const AcdgFormField.checkboxWithInput({
    super.key,
    required this.label,
    required this.inputPlaceholder,
    required this.isChecked,
    this.inputController,
    this.onCheckChanged,
    this.onInputChanged,
    this.underlineWidth,
    this.errorText,
    this.inputFormatters,
    this.inverted = false,
    this.enabled = true,
  }) : _type = _AcdgFormFieldType.checkboxWithInput,
       placeholder = null,
       controller = null,
       keyboardType = null,
       onChanged = null,
       initialValue = null,
       options = null,
       selectedValue = null,
       selectionType = SelectionType.checkbox,
       direction = Axis.horizontal,
       readOnly = false,
       dropdownItems = null,
       dropdownValue = null,
       onDropdownChanged = null;

  const AcdgFormField.dropdown({
    super.key,
    required this.label,
    required this.dropdownItems,
    required this.dropdownValue,
    this.onDropdownChanged,
    this.inverted = false,
    this.enabled = true,
    this.errorText,
  }) : _type = _AcdgFormFieldType.dropdown,
       placeholder = null,
       controller = null,
       keyboardType = null,
       onChanged = null,
       underlineWidth = null,
       initialValue = null,
       inputFormatters = null,
       options = null,
       selectedValue = null,
       selectionType = SelectionType.checkbox,
       direction = Axis.horizontal,
       readOnly = false,
       isChecked = null,
       onCheckChanged = null,
       inputPlaceholder = null,
       inputController = null,
       onInputChanged = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: IgnorePointer(
            ignoring: !enabled,
            child: _buildContent(context, width),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, double width) {
    return switch (_type) {
      _AcdgFormFieldType.text => _buildTextField(width),
      _AcdgFormFieldType.selection => _buildSelectionField(width),
      _AcdgFormFieldType.textWithInlineSelection =>
        _buildTextWithInlineSelection(width),
      _AcdgFormFieldType.checkboxSimple => _buildCheckboxSimple(width),
      _AcdgFormFieldType.checkboxWithInput => _buildCheckboxWithInput(width),
      _AcdgFormFieldType.dropdown => _buildDropdownField(width),
    };
  }

  Widget _buildLabel(double width) {
    return AcdgText(
      label,
      variant: AcdgTextVariant.headingMedium,
      color: inverted ? AppColors.textOnDark : AppColors.textPrimary,
    );
  }

  Widget _buildTextField(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(width),
        const SizedBox(height: 8),
        SizedBox(
          width: underlineWidth,
          child: AcdgUnderlineInput(
            hintText: placeholder,
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            onChanged: onChanged,
            initialValue: initialValue,
            enabled: enabled && !readOnly,
            errorText: errorText,
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField(double width) {
    final children = options!.map((opt) {
      final isSelected = selectedValue == opt.value;
      return Padding(
        padding: direction == Axis.horizontal
            ? EdgeInsets.only(right: width < AppBreakpoints.tablet ? 24 : 40)
            : const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectionType == SelectionType.checkbox)
              AcdgCheckbox(
                value: isSelected,
                onChanged: (val) => onChanged?.call(opt.value),
                activeColor: inverted ? AppColors.textOnDark : null,
              )
            else
              AcdgRadioButton(
                value: opt.value,
                groupValue: selectedValue,
                onChanged: (val) => onChanged?.call(opt.value),
                activeColor: inverted ? AppColors.textOnDark : null,
              ),
            const SizedBox(width: 12),
            AcdgText(
              opt.label,
              variant: AcdgTextVariant.selectionLabel,
              color: inverted ? AppColors.textOnDark : AppColors.textMuted,
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(width),
        const SizedBox(height: 8),
        if (direction == Axis.horizontal)
          Wrap(children: children)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
      ],
    );
  }

  Widget _buildTextWithInlineSelection(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel(width),
            const SizedBox(width: 32),
            ...options!.map((opt) {
              final isSelected = selectedValue == opt.value;
              return Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AcdgCheckbox(
                      value: isSelected,
                      onChanged: (val) => onInputChanged?.call(opt.value),
                    ),
                    const SizedBox(width: 8),
                    AcdgText(
                      opt.label,
                      variant: AcdgTextVariant.selectionLabel,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: underlineWidth,
          child: AcdgUnderlineInput(
            hintText: placeholder,
            controller: controller,
            onChanged: onChanged,
            initialValue: initialValue,
            errorText: errorText,
            inputFormatters: inputFormatters,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxSimple(double width) {
    return Row(
      children: [
        AcdgCheckbox(value: isChecked ?? false, onChanged: onCheckChanged),
        const SizedBox(width: 32),
        _buildLabel(width),
      ],
    );
  }

  Widget _buildCheckboxWithInput(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckboxSimple(width),
        if (isChecked ?? false) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: SizedBox(
              width: underlineWidth ?? 642,
              child: AcdgUnderlineInput(
                hintText: inputPlaceholder,
                controller: inputController,
                onChanged: onInputChanged,
                errorText: errorText,
                inputFormatters: inputFormatters,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField(double width) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(width),
        const SizedBox(height: 8),
        AcdgDropdown(
          items: dropdownItems!.cast<DropdownMenuItem<dynamic>>(),
          value: dropdownValue,
          onChanged: onDropdownChanged,
          inverted: inverted,
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.caption(
              width,
            ).copyWith(color: AppColors.danger, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
