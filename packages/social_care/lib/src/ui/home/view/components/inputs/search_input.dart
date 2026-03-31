import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';

final class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const SearchInput({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0x33261D11), width: 1.5),
            color: const Color(0x80FAF0E0),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: Color(0x80261D11)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged?.call(),
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                    color: Color(0xFF261D11),
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: HomeLn10.searchPlaceholder,
                    hintStyle: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      fontSize: 18,
                      color: Color(0x80261D11),
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged?.call();
                  },
                  child: const Icon(Icons.close, size: 18, color: Color(0x80261D11)),
                ),
            ],
          ),
        );
      },
    );
  }
}
