import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class HoverableRelationshipItem extends StatefulWidget {
  final LookupItem item;
  final bool isSelected;
  final bool isHighlighted;
  final bool enabled;
  final VoidCallback onTap;

  const HoverableRelationshipItem({
    super.key,
    required this.item,
    required this.isSelected,
    this.isHighlighted = false,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<HoverableRelationshipItem> createState() =>
      _HoverableRelationshipItemState();
}

class _HoverableRelationshipItemState extends State<HoverableRelationshipItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.background.withValues(alpha: 0.1)
                  : _isHovered
                  ? AppColors.background.withValues(alpha: 0.05)
                  : widget.isHighlighted
                  ? AppColors.background.withValues(alpha: 0.02)
                  : Colors.transparent,
              border: widget.isHighlighted
                  ? Border.all(
                      color: AppColors.background.withValues(alpha: 0.2),
                    )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.item.descricao,
              style: TextStyle(
                color: AppColors.background,
                fontSize: 14,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
