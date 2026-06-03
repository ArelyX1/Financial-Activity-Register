import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileInfoRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const ProfileInfoRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.bodySmall.copyWith(color: theme.secondaryText)),
                const SizedBox(height: 2),
                Text(value, style: theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
