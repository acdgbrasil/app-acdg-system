import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';

class FichaRow extends StatefulWidget {
  final FichaStatus ficha;
  final bool isLast;

  const FichaRow({super.key, required this.ficha, this.isLast = false});

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
        onTap: () {},
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 1.0 : (widget.ficha.filled ? 0.9 : 0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: widget.isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0x26F2E2C4)),
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
                      color: Color(0xFFF2E2C4),
                    ),
                  ),
                ),
                Icon(
                  widget.ficha.filled ? Icons.chevron_right : Icons.add,
                  size: 20,
                  color: const Color(0x99F2E2C4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
