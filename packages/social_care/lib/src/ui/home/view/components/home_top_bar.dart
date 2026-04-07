import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';
import 'home_tab_button.dart';

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
            icon: const Icon(
              Icons.menu,
              size: 24,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 32),
          HomeTabButton(
            label: HomeLn10.tabFamilies,
            isActive: activeTab == 'familias',
            onTap: () => onTabChanged('familias'),
          ),
          const SizedBox(width: 4),
          HomeTabButton(
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
              color: AppColors.textMuted,
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
