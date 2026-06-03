import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeadCardWidget extends StatelessWidget {
  final String name;
  final String? document;
  final String? phone;
  final String? status;
  final VoidCallback onTap;

  const LeadCardWidget({
    super.key,
    required this.name,
    this.document,
    this.phone,
    this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final statusColor = status == 'Nuevo' ? theme.info
        : status == 'Contactado' ? theme.warning
        : status == 'En Proceso' ? theme.primary
        : theme.success;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E1E1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: theme.titleMedium.copyWith(color: theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
                  if (document != null) ...[
                    const SizedBox(height: 2),
                    Text('DNI: $document', style: theme.bodySmall.copyWith(color: theme.secondaryText)),
                  ],
                  if (phone != null) ...[
                    const SizedBox(height: 2),
                    Text(phone!, style: theme.bodySmall.copyWith(color: theme.secondaryText)),
                  ],
                ],
              ),
            ),
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status!,
                  style: theme.labelSmall.copyWith(color: statusColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
