import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/login_header_widget.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../components/checkbox_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _remember = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.secondaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const LoginHeaderWidget(
                title: 'Incasur Gestor',
                subtitle: 'Inicia sesión para gestionar tus actividades financieras',
              ),
              const SizedBox(height: 40),
              TextFieldWidget(
                controller: _userController,
                label: 'Usuario',
                hint: 'Ingrese su usuario',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              TextFieldWidget(
                controller: _passController,
                label: 'Contraseña',
                hint: 'Ingrese su contraseña',
                prefixIcon: Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CheckboxWidget(
                    label: 'Recordar usuario',
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ButtonWidget(
                text: 'Iniciar Sesión',
                icon: Icons.login,
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: theme.bodyMedium.copyWith(color: theme.primary),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
