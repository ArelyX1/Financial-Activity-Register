import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoginHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoginHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.account_balance, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.headlineMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
