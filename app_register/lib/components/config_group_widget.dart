import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'setting_row_widget.dart';

class ConfigGroupWidget extends StatelessWidget {
  final String title;
  final String? description;
  final List<SettingRowWidget> items;

  const ConfigGroupWidget({
    super.key,
    required this.title,
    this.description,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.titleSmall.copyWith(color: theme.primaryText)),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description!, style: theme.bodySmall.copyWith(color: theme.secondaryText)),
          ],
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}
