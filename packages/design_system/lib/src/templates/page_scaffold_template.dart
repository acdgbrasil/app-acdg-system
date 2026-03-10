import 'package:flutter/material.dart';

import '../tokens/acdg_colors.dart';
import '../tokens/acdg_typography.dart';

/// Page scaffold template — scaffold with appBar, conditional sidebar, actions.
///
/// Shows sidebar when width >= [sidebarBreakpoint].
class PageScaffoldTemplate extends StatelessWidget {
  const PageScaffoldTemplate({
    super.key,
    required this.title,
    required this.body,
    this.sidebar,
    this.actions,
    this.showBackButton = false,
    this.onBack,
    this.sidebarBreakpoint = 1024,
  });

  final String title;
  final Widget body;
  final Widget? sidebar;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double sidebarBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          title,
          style: AcdgTypography.headingMedium.copyWith(
            color: AcdgColors.onSurface,
          ),
        ),
        actions: actions,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar =
              sidebar != null && constraints.maxWidth >= sidebarBreakpoint;

          if (showSidebar) {
            return Row(
              children: [
                SizedBox(width: 280, child: sidebar),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            );
          }

          return body;
        },
      ),
    );
  }
}
