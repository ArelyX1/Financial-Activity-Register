import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatPillWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const StatPillWidget({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final bgColor = color ?? theme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: bgColor, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: ',
            style: theme.labelSmall.copyWith(color: theme.secondaryText),
          ),
          Text(
            value,
            style: theme.labelSmall.copyWith(color: bgColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
