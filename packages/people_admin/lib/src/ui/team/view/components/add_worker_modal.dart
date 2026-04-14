import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/team_l10n.dart';
import '../../view_models/add_worker_form_state.dart';

class AddWorkerModal extends StatefulWidget {
  final AddWorkerFormState formState;
  final bool Function() canSubmit;
  final Future<void> Function() onRegister;

  const AddWorkerModal({
    super.key,
    required this.formState,
    required this.canSubmit,
    required this.onRegister,
  });

  @override
  State<AddWorkerModal> createState() => _AddWorkerModalState();
}

class _AddWorkerModalState extends State<AddWorkerModal> {
  bool _showErrors = false;
  bool _submitting = false;

  Future<void> _handleRegister() async {
    if (!widget.canSubmit()) {
      setState(() => _showErrors = true);
      return;
    }

    setState(() => _submitting = true);

    await widget.onRegister();

    if (!mounted) return;

    setState(() => _submitting = false);

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.formState;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.buttonShadow,
                  offset: Offset(-40, 40),
                  blurRadius: 60,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TeamL10n.modalTitleAdd,
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textOnDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.close,
                              color: AppColors.danger,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    _ModalField(
                      label: TeamL10n.fieldFullName,
                      placeholder: TeamL10n.fieldFullName,
                      controller: fs.fullName,
                      errorText: _showErrors ? fs.fullNameError : null,
                    ),
                    const SizedBox(height: 16),

                    // CPF
                    _ModalField(
                      label: TeamL10n.fieldCpf,
                      placeholder: '000.000.000-00',
                      controller: fs.cpf,
                      inputFormatters: AppMasks.cpf,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _ModalField(
                      label: TeamL10n.fieldEmail,
                      placeholder: 'nome@exemplo.com',
                      controller: fs.email,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _showErrors ? fs.emailError : null,
                    ),
                    const SizedBox(height: 16),

                    // Birth Date
                    _ModalField(
                      label: TeamL10n.fieldBirthDate,
                      placeholder: 'DD/MM/AAAA',
                      controller: fs.birthDate,
                      inputFormatters: AppMasks.date,
                      keyboardType: TextInputType.number,
                      errorText: _showErrors ? fs.birthDateError : null,
                    ),
                    const SizedBox(height: 16),

                    // Role
                    Text(
                      TeamL10n.fieldRole,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String?>(
                      valueListenable: fs.selectedRole,
                      builder: (context, role, _) {
                        return Column(
                          children: [
                            _RoleOption(
                              label: TeamL10n.roleSocialWorker,
                              value: 'social_worker',
                              groupValue: role,
                              onChanged: (v) => fs.selectedRole.value = v,
                            ),
                            const SizedBox(height: 4),
                            _RoleOption(
                              label: TeamL10n.roleAdmin,
                              value: 'admin',
                              groupValue: role,
                              onChanged: (v) => fs.selectedRole.value = v,
                            ),
                            if (_showErrors && fs.roleError != null) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  fs.roleError!,
                                  style: const TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Initial Password
                    _ModalField(
                      label: TeamL10n.fieldInitialPassword,
                      placeholder: TeamL10n.fieldInitialPassword,
                      controller: fs.initialPassword,
                    ),

                    const SizedBox(height: 24),
                    Divider(
                      color: AppColors.background.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textOnDark,
                            shape: const StadiumBorder(
                              side: BorderSide(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            TeamL10n.buttonCancel,
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _submitting ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            _submitting ? '...' : TeamL10n.buttonRegister,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ],
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
}

class _ModalField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  const _ModalField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textAntiFlash,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: hasError
                    ? AppColors.danger
                    : AppColors.textMuted.withValues(alpha: 0.4),
                width: hasError ? 2.0 : 1.0,
              ),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            cursorColor: AppColors.accent,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 15,
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onChanged;

  const _RoleOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.accent : AppColors.textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
