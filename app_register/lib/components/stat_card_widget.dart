import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final double? percentage;

  const StatCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final cardColor = color ?? theme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cardColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.titleLarge.copyWith(color: theme.primaryText, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  percentage! >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: percentage! >= 0 ? theme.success : theme.error,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentage!.abs().toStringAsFixed(1)}%',
                  style: theme.labelSmall.copyWith(
                    color: percentage! >= 0 ? theme.success : theme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
