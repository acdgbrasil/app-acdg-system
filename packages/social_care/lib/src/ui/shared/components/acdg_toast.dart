import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum ToastType { success, error, warning }

class AcdgToast extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onDismissed;

  const AcdgToast({
    super.key,
    required this.message,
    this.type = ToastType.error,
    this.onDismissed,
  });

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.error,
    VoidCallback? onDismissed,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        onDismissed: () {
          entry.remove();
          onDismissed?.call();
        },
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<AcdgToast> createState() => _AcdgToastState();
}

class _AcdgToastState extends State<AcdgToast> {
  @override
  Widget build(BuildContext context) {
    return _ToastOverlay(
      message: widget.message,
      type: widget.type,
      onDismissed: widget.onDismissed,
    );
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.type,
    this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  static const _green = Color(0xFF2E7D32);
  static const _red = AppColors.danger;
  static const _amber = AppColors.warning;
  static const _bgWhite = AppColors.surfaceLight;

  Color get _backgroundColor => switch (widget.type) {
    ToastType.success => _green,
    ToastType.error => _red,
    ToastType.warning => _amber,
  };

  String get _icon => switch (widget.type) {
    ToastType.success => '✓',
    ToastType.error => '✕',
    ToastType.warning => '!',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 28, 14),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgWhite.withValues(alpha: 0.25),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _icon,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _bgWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _bgWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
