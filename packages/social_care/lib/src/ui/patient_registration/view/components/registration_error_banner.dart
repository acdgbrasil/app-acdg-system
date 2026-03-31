import 'package:flutter/material.dart';

class RegistrationErrorBanner extends StatelessWidget {
  final List<String> errors;

  const RegistrationErrorBanner({super.key, required this.errors});

  static const _red = Color(0xFFA6290D);
  static const _redBg = Color(0x0FA6290D);
  static const _redBg2 = Color(0x1FA6290D);
  static const _bgWhite = Color(0xFFFFFBF4);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * -8, 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: _redBg,
          border: Border.all(color: _redBg2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '!',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _bgWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errors.length == 1
                        ? errors[0]
                        : '${errors.length} campos precisam de atenção',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _red,
                    ),
                  ),
                ),
              ],
            ),
            if (errors.length > 1) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 7, right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _red.withValues(alpha: 0.5),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: _red,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
