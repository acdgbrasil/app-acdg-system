import 'package:flutter/material.dart';

import '../atoms/acdg_icon_button.dart';
import '../atoms/acdg_text.dart';
import '../tokens/app_breakpoints.dart';
import '../tokens/app_colors.dart';

class BreadcrumbItem {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.isActive = false,
    this.onTap,
  });
}

/// The top header organism for registration pages.
///
/// Contains: Nav bar (hamburger + breadcrumbs), spacing, Page Title, and optional trailing action.
class AcdgRegistrationHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<BreadcrumbItem> breadcrumbs;
  final Widget? trailingAction;
  final VoidCallback? onMenuTap;

  const AcdgRegistrationHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.breadcrumbs,
    this.trailingAction,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = AppBreakpoints.isDesktop(width);
        final isTablet = AppBreakpoints.isTablet(width);

        final gridMargin = isDesktop ? 72.0 : (isTablet ? 40.0 : 16.0);
        final navTopMargin = isDesktop ? 72.0 : (isTablet ? 40.0 : 24.0);
        final titleTopMargin = isDesktop ? 72.0 : (isTablet ? 56.0 : 48.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(gridMargin, navTopMargin, gridMargin, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navigation Bar
              Row(
                children: [
                  AcdgIconButton(
                    icon: Icons.menu,
                    onPressed: onMenuTap,
                    size: isDesktop ? 48 : (isTablet ? 32 : 24),
                  ),
                  SizedBox(width: isDesktop ? 56 : (isTablet ? 40 : 48)),
                  ..._buildBreadcrumbs(width),
                ],
              ),

              SizedBox(height: titleTopMargin),

              // 2. Title Layer
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AcdgText(
                      title,
                      variant: AcdgTextVariant.displayLarge,
                    ),
                  ),
                  if (trailingAction != null) ...[
                    const SizedBox(width: 16),
                    trailingAction!,
                  ],
                ],
              ),

              // 3. Optional Subtitle
              if (subtitle != null) ...[
                SizedBox(height: isDesktop ? 48 : (isTablet ? 32 : 24)),
                Padding(
                  padding: EdgeInsets.only(
                    left: isDesktop ? 32 : (isTablet ? 24 : 0),
                  ),
                  child: AcdgText(
                    subtitle!,
                    variant: AcdgTextVariant.headingLarge,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBreadcrumbs(double width) {
    final List<Widget> widgets = [];
    final isDesktop = AppBreakpoints.isDesktop(width);

    for (int i = 0; i < breadcrumbs.length; i++) {
      final item = breadcrumbs[i];
      widgets.add(
        GestureDetector(
          onTap: item.onTap,
          child: Container(
            decoration: BoxDecoration(
              border: item.isActive
                  ? const Border(
                      bottom: BorderSide(color: AppColors.border, width: 1.0),
                    )
                  : null,
            ),
            child: AcdgText(item.label, variant: AcdgTextVariant.headingSmall),
          ),
        ),
      );

      if (i < breadcrumbs.length - 1) {
        widgets.add(
          SizedBox(
            width: isDesktop ? 56 : (AppBreakpoints.isTablet(width) ? 32 : 24),
          ),
        );
      }
    }
    return widgets;
  }
}
