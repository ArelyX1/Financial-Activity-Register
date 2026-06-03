import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'text_field_widget.dart';

class FormSection3Widget extends StatelessWidget {
  final TextEditingController plateController;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController yearController;
  final TextEditingController colorController;

  const FormSection3Widget({
    super.key,
    required this.plateController,
    required this.brandController,
    required this.modelController,
    required this.yearController,
    required this.colorController,
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
              Icon(Icons.directions_car, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Vehículo (Colateral)', style: theme.titleSmall.copyWith(color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFieldWidget(controller: plateController, label: 'Placa', hint: 'ABC-123', prefixIcon: Icons.pin)),
              const SizedBox(width: 12),
              Expanded(child: TextFieldWidget(controller: brandController, label: 'Marca', hint: 'Toyota', prefixIcon: Icons.business)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFieldWidget(controller: modelController, label: 'Modelo', hint: 'Corolla', prefixIcon: Icons.model_training)),
              const SizedBox(width: 12),
              Expanded(child: TextFieldWidget(controller: yearController, label: 'Año', hint: '2024', prefixIcon: Icons.calendar_today, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          TextFieldWidget(controller: colorController, label: 'Color', hint: 'Rojo', prefixIcon: Icons.palette),
        ],
      ),
    );
  }
}
