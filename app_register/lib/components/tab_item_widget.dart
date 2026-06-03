import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TabItemWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const TabItemWidget({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: selected ? Colors.white : theme.secondaryText,
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.labelMedium.copyWith(
                color: selected ? Colors.white : theme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
