import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'text_field_widget.dart';

class FormCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> fields;

  const FormCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
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
              Icon(icon, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.titleSmall.copyWith(color: theme.primaryText)),
            ],
          ),
          const SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }

  static Widget field(String label, String hint, TextEditingController controller, {IconData? icon, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFieldWidget(
        controller: controller,
        label: label,
        hint: hint,
        prefixIcon: icon,
        keyboardType: keyboardType,
      ),
    );
  }
}
