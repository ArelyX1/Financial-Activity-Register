import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final ButtonVariant variant;

  const ButtonWidget({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colors = [
      theme.primary,
      theme.secondary,
      theme.tertiary,
      Colors.transparent,
    ][variant.index];
    final textColors = [
      Colors.white,
      Colors.white,
      Colors.white,
      theme.primary,
    ][variant.index];
    final borderColors = [
      Colors.transparent,
      Colors.transparent,
      Colors.transparent,
      theme.primary,
    ][variant.index];

    Widget button = Container(
      height: 50,
      decoration: BoxDecoration(
        color: colors,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColors),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColors, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: theme.labelLarge.copyWith(color: textColors),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

enum ButtonVariant { primary, secondary, tertiary, outline }
