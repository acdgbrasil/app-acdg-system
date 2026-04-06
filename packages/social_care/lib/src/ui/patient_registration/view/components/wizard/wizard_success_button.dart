import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class WizardSuccessButton extends StatefulWidget {
  const WizardSuccessButton({super.key});

  @override
  State<WizardSuccessButton> createState() => _WizardSuccessButtonState();
}

class _WizardSuccessButtonState extends State<WizardSuccessButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
              color: AppColors.buttonShadow,
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CustomPaint(
                  size: const Size(20, 20),
                  painter: _CheckPainter(progress: value),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              ReferencePersonLn10.savedSuccessfully,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 16,
                color: AppColors.textOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3);

    final metric = path.computeMetrics().first;
    final partial = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(partial, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
