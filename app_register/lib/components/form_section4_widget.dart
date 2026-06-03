import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'text_field_widget.dart';

class FormSection4Widget extends StatelessWidget {
  final TextEditingController observationsController;
  final TextEditingController referenceController;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final bool hasGuarantor;
  final ValueChanged<bool> onGuarantorChanged;

  const FormSection4Widget({
    super.key,
    required this.observationsController,
    required this.referenceController,
    this.selectedStatus,
    required this.onStatusChanged,
    required this.hasGuarantor,
    required this.onGuarantorChanged,
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
          Row(
            children: [
              Icon(Icons.miscellaneous_services, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Otros Gestión', style: theme.titleSmall.copyWith(color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldWidget(
            controller: observationsController,
            label: 'Observaciones',
            hint: 'Notas adicionales',
            prefixIcon: Icons.notes,
            multiline: true,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: referenceController,
            label: 'Referencia',
            hint: 'Código de referencia',
            prefixIcon: Icons.tag,
          ),
          const SizedBox(height: 12),
          _buildStatusDropdown(context),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => onGuarantorChanged(!hasGuarantor),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: hasGuarantor ? theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: hasGuarantor ? theme.primary : const Color(0xFFADB5BD), width: 1.5),
                  ),
                  child: hasGuarantor ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Text('Requiere Garante', style: theme.bodyMedium.copyWith(color: theme.primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    final theme = AppTheme.of(context);
    final items = ['Pendiente', 'En Proceso', 'Completado', 'Derivado'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('Estado', style: theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.alternate,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E1E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              hint: Text('Seleccione estado', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.bodyMedium.copyWith(color: theme.primaryText)))).toList(),
              onChanged: onStatusChanged,
            ),
          ),
        ),
      ],
    );
  }
}
