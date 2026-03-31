import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';

class HomeTopBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final int familyCount;
  final Widget? syncIndicator;

  const HomeTopBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.familyCount,
    this.syncIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, size: 24, color: Color(0xFF261D11)),
            onPressed: () {},
          ),
          const SizedBox(width: 32),
          _TabButton(
            label: HomeLn10.tabFamilies,
            isActive: activeTab == 'familias',
            onTap: () => onTabChanged('familias'),
          ),
          const SizedBox(width: 4),
          _TabButton(
            label: HomeLn10.tabRegistration,
            isActive: activeTab == 'cadastro',
            onTap: () => onTabChanged('cadastro'),
          ),
          const Spacer(),
          Text(
            HomeLn10.familyCounter(familyCount),
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: Color(0x80261D11),
            ),
          ),
          if (syncIndicator != null) ...[
            const SizedBox(width: 16),
            syncIndicator!,
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x14261D11) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
            color: const Color(0xFF261D11),
          ),
        ),
      ),
    );
  }
}
