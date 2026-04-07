import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A pure StatelessWidget for tab navigation in modal dialogs.
///
/// Extracted from `_buildLeftColumn` / `_buildRightColumn` in modal
/// widgets to comply with the Gold Standard's Atomic Design rules:
/// - No private `_build*` methods in Views
/// - Views are "dumb" — they receive data via constructor and
///   forward user intents via callbacks
///
/// Usage:
/// ```dart
/// ModalSideMenu(
///   currentTabIndex: viewModel.activeTab,
///   tabs: ['Info', 'Docs', 'History'],
///   onTabSelected: viewModel.setActiveTab,
/// )
/// ```
class ModalSideMenu extends StatelessWidget {
  const ModalSideMenu({
    super.key,
    required this.currentTabIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  /// The currently active tab index.
  final int currentTabIndex;

  /// Labels for each tab.
  final List<String> tabs;

  /// Callback fired when the user taps a tab.
  /// The View does NOT manage tab state — it forwards the intent.
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tabs.length; i++)
          GestureDetector(
            onTap: () => onTabSelected(i),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: i == currentTabIndex
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: i == currentTabIndex
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == currentTabIndex
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
