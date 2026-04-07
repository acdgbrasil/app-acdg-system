import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';

class FichaRow extends StatefulWidget {
  final FichaStatus ficha;
  final bool isLast;
  final VoidCallback? onTap;

  const FichaRow({
    super.key,
    required this.ficha,
    this.isLast = false,
    this.onTap,
  });

  @override
  State<FichaRow> createState() => _FichaRowState();
}

class _FichaRowState extends State<FichaRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 1.0 : (widget.ficha.filled ? 0.9 : 0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: widget.isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppColors.background.withValues(alpha: 0.15),
                      ),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.ficha.name,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppColors.background,
                    ),
                  ),
                ),
                Icon(
                  widget.ficha.filled ? Icons.chevron_right : Icons.add,
                  size: 20,
                  color: AppColors.background.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
