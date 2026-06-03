import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? theme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? theme.primary : theme.secondaryText,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.bodyMedium.copyWith(
                  color: selected ? theme.primary : theme.primaryText,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
