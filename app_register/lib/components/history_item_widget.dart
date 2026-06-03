import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryItemWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? date;
  final String? status;
  final IconData? icon;
  final VoidCallback onTap;

  const HistoryItemWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.status,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final statusColor = status == 'Completado' ? theme.success
        : status == 'Pendiente' ? theme.warning
        : status == 'En Proceso' ? theme.info
        : theme.secondaryText;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E1E1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.primary, size: 20),
              )
            else
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.bodySmall.copyWith(color: theme.secondaryText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (date != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: theme.secondaryText),
                        const SizedBox(width: 4),
                        Text(date!, style: theme.labelSmall.copyWith(color: theme.secondaryText)),
                        if (status != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status!,
                              style: theme.labelSmall.copyWith(color: statusColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}
