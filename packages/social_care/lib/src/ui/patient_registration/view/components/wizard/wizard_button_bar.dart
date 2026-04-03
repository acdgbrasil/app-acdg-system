import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class WizardButtonBar extends StatelessWidget {
  final int currentStep;
  final bool isLastStep;
  final bool isNextEnabled;
  final bool isSuccess;
  final double padding;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const WizardButtonBar({
    super.key,
    required this.currentStep,
    required this.isLastStep,
    required this.isNextEnabled,
    required this.padding,
    this.isSuccess = false,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            WizardButton(
              label: ReferencePersonLn10.btnBack,
              icon: Icons.arrow_back,
              isPrimary: false,
              onPressed: onBack,
            )
          else
            const SizedBox.shrink(),
          if (isSuccess)
            const _SuccessButton()
          else
            WizardButton(
              label: isLastStep ? ReferencePersonLn10.btnSave : ReferencePersonLn10.btnNext,
              icon: isLastStep ? Icons.check : Icons.arrow_forward,
              isPrimary: true,
              onPressed: isNextEnabled ? onNext : null,
            ),
        ],
      ),
    );
  }
}

class _SuccessButton extends StatefulWidget {
  const _SuccessButton();

  @override
  State<_SuccessButton> createState() => _SuccessButtonState();
}

class _SuccessButtonState extends State<_SuccessButton>
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
            Text(
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

class WizardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const WizardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? AppColors.primary : Colors.transparent;
    final textColor = isPrimary ? AppColors.background : AppColors.textPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: AppColors.inputLine, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPrimary) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );
  }
}
