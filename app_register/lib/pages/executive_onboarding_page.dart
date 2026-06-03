import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/form_card_widget.dart';
import '../components/button_widget.dart';

class ExecutiveOnboardingPage extends StatefulWidget {
  const ExecutiveOnboardingPage({super.key});

  @override
  State<ExecutiveOnboardingPage> createState() => _ExecutiveOnboardingPageState();
}

class _ExecutiveOnboardingPageState extends State<ExecutiveOnboardingPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Onboarding', style: theme.titleLarge.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registro de Ejecutivo', style: theme.headlineSmall.copyWith(color: theme.primaryText)),
            const SizedBox(height: 4),
            Text('Complete sus datos para comenzar', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
            const SizedBox(height: 20),
            FormCardWidget(
              title: 'Datos Personales',
              icon: Icons.person,
              fields: [
                FormCardWidget.field('Nombre Completo', 'Ingrese su nombre', _nameCtrl, icon: Icons.person_outline),
                FormCardWidget.field('Correo Electrónico', 'Ingrese su correo', _emailCtrl, icon: Icons.email, keyboardType: TextInputType.emailAddress),
                FormCardWidget.field('Teléfono', 'Ingrese su teléfono', _phoneCtrl, icon: Icons.phone, keyboardType: TextInputType.phone),
              ],
            ),
            const SizedBox(height: 16),
            FormCardWidget(
              title: 'Datos Laborales',
              icon: Icons.work,
              fields: [
                FormCardWidget.field('Código de Empleado', 'Ingrese su código', _codeCtrl, icon: Icons.badge),
                FormCardWidget.field('Sucursal / Agencia', 'Ingrese sucursal', _branchCtrl, icon: Icons.business),
              ],
            ),
            const SizedBox(height: 24),
            ButtonWidget(
              text: 'Guardar y Continuar',
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/dashboard'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
