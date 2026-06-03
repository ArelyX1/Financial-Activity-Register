import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TurnOption { morning, afternoon, both }

class TurnSelectorWidget extends StatelessWidget {
  final TurnOption value;
  final ValueChanged<TurnOption> onChanged;

  const TurnSelectorWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildOption(context, 'Mañana', TurnOption.morning, Icons.wb_sunny),
        const SizedBox(width: 8),
        _buildOption(context, 'Tarde', TurnOption.afternoon, Icons.nightlight_round),
        const SizedBox(width: 8),
        _buildOption(context, 'Ambos', TurnOption.both, Icons.swap_horiz),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String label, TurnOption option, IconData icon) {
    final theme = AppTheme.of(context);
    final selected = value == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.primary : theme.alternate,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? theme.primary : const Color(0xFFE1E1E1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : theme.secondaryText, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.labelSmall.copyWith(
                  color: selected ? Colors.white : theme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
