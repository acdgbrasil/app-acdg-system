import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum CircleButtonVariant { normal, close }

class CircleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final CircleButtonVariant variant;
  final String? tooltip;

  const CircleButton({
    super.key,
    this.onPressed,
    required this.child,
    this.variant = CircleButtonVariant.normal,
    this.tooltip,
  });

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  bool _hovered = false;

  bool get _isClose => widget.variant == CircleButtonVariant.close;

  Color get _background {
    if (!_hovered) return Colors.transparent;
    return _isClose
        ? AppColors.danger.withValues(alpha: 0.2)
        : AppColors.background.withValues(alpha: 0.1);
  }

  Color get _borderColor {
    return _isClose
        ? AppColors.background.withValues(alpha: 0.4)
        : AppColors.background.withValues(alpha: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _background,
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(
              size: 18,
              color: _isClose ? AppColors.danger : AppColors.background,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
