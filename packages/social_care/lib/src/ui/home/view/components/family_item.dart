import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

class FamilyItem extends StatefulWidget {
  final PatientSummary family;
  final bool isSelected;
  final bool isAnySelected;
  final VoidCallback onTap;

  const FamilyItem({
    super.key,
    required this.family,
    required this.isSelected,
    required this.isAnySelected,
    required this.onTap,
  });

  @override
  State<FamilyItem> createState() => _FamilyItemState();
}

class _FamilyItemState extends State<FamilyItem> {
  bool _hovered = false;

  bool get _isHighlighted =>
      widget.isSelected ||
      (_hovered && !widget.isAnySelected) ||
      (_hovered && widget.isSelected);

  bool get _isFaded => widget.isAnySelected && !widget.isSelected && !_hovered;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: _isHighlighted
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 40,
                  height: 1.2,
                  color: _isFaded ? AppColors.textMuted : AppColors.textPrimary,
                ),
                child: Text(widget.family.lastName),
              ),
              const SizedBox(width: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHighlighted ? 1.0 : 0.0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _isHighlighted ? Offset.zero : const Offset(-0.05, 0),
                  child: Text(
                    '${widget.family.firstName} · ${HomeLn10.membersLabel(widget.family.memberCount)}',
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
