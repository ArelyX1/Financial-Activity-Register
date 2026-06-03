import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwitchComponentWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchComponentWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: theme.primary.withValues(alpha: 0.4),
    );
  }
}
