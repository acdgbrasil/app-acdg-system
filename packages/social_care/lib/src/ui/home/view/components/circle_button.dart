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
    return _isClose ? const Color(0x33A6290D) : const Color(0x1AF2E2C4);
  }

  Color get _borderColor {
    return _isClose ? const Color(0x66F2E2C4) : const Color(0x40F2E2C4);
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
              color: _isClose ? const Color(0xFFA6290D) : const Color(0xFFF2E2C4),
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
