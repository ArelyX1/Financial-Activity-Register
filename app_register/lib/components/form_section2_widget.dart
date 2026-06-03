import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'text_field_widget.dart';

class FormSection2Widget extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController dateController;
  final String? selectedMethod;
  final String? selectedBank;
  final ValueChanged<String?> onMethodChanged;
  final ValueChanged<String?> onBankChanged;
  final VoidCallback onSelectDate;

  const FormSection2Widget({
    super.key,
    required this.amountController,
    required this.dateController,
    this.selectedMethod,
    this.selectedBank,
    required this.onMethodChanged,
    required this.onBankChanged,
    required this.onSelectDate,
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
              Icon(Icons.attach_money, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Desembolsos', style: theme.titleSmall.copyWith(color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldWidget(
            controller: amountController,
            label: 'Monto',
            hint: 'Ingrese monto',
            prefixIcon: Icons.monetization_on_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onSelectDate,
            child: AbsorbPointer(
              child: TextFieldWidget(
                controller: dateController,
                label: 'Fecha',
                hint: 'Seleccione fecha',
                prefixIcon: Icons.calendar_today,
                suffixIcon: Icons.arrow_drop_down,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _dropdown(context, 'Método de Desembolso', ['Efectivo', 'Transferencia', 'Cheque', 'Depósito'], selectedMethod, onMethodChanged),
          const SizedBox(height: 12),
          _dropdown(context, 'Banco', ['BCP', 'Interbank', 'Scotiabank', 'BBVA', 'Banbif'], selectedBank, onBankChanged),
        ],
      ),
    );
  }

  Widget _dropdown(BuildContext context, String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
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
              hint: Text('Seleccione', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.bodyMedium.copyWith(color: theme.primaryText)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
