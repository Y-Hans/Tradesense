import 'package:flutter/material.dart';
import '../../tokens/spacing.dart';

/// A reusable Bottom Navigation item definition
class NavItemData {
  final String label;
  final Widget icon;
  final Widget activeIcon;

  const NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// The custom Bottom Navigation Bar for TradeSense.
///
/// Example usage:
/// ```dart
/// AppBottomNavBar(
///   items: myNavItems,
///   currentIndex: 0,
///   onTap: (index) => print('Tapped $index'),
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  /// List of navigation items
  final List<NavItemData> items;
  
  /// The currently selected index
  final int currentIndex;
  
  /// Callback when an item is tapped
  final ValueChanged<int> onTap;

  AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBg = isDark ? Theme.of(context).colorScheme.surface : theme.colorScheme.surface;
    final borderColor = isDark ? Theme.of(context).dividerColor : theme.dividerColor;
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = isDark ? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey : Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          final item = items[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                      child: isSelected ? item.activeIcon : item.icon,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected ? selectedColor : unselectedColor,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
