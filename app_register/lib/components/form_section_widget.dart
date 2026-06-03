import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'text_field_widget.dart';

class FormSectionWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? selectedClientType;
  final ValueChanged<String?> onClientTypeChanged;

  const FormSectionWidget({
    super.key,
    required this.nameController,
    required this.idController,
    required this.phoneController,
    required this.emailController,
    this.selectedClientType,
    required this.onClientTypeChanged,
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
              Icon(Icons.person, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Datos del Cliente', style: theme.titleSmall.copyWith(color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldWidget(
            controller: nameController,
            label: 'Nombre Completo',
            hint: 'Ingrese nombre completo',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: idController,
            label: 'DNI / Documento',
            hint: 'Ingrese documento',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: phoneController,
            label: 'Teléfono',
            hint: 'Ingrese teléfono',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: emailController,
            label: 'Correo Electrónico',
            hint: 'Ingrese correo',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildDropdown(context, 'Tipo de Cliente', ['Nuevo', 'Regular', 'VIP'], selectedClientType, onClientTypeChanged),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: theme.bodyMedium.copyWith(color: theme.primaryText, fontWeight: FontWeight.w600)),
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
              value: value,
              isExpanded: true,
              hint: Text('Seleccione tipo', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.bodyMedium.copyWith(color: theme.primaryText)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
