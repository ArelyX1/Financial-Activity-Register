import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../models/app_state.dart';

class RegisterAccountPage extends StatefulWidget {
  const RegisterAccountPage({super.key});

  @override
  State<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends State<RegisterAccountPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _formT;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formT = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cache = context.read<AppState>().registerCache;
      _usernameController.text = cache.username;
      _emailController.text = cache.email;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveAndNext() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty) {
      _showError('Ingrese un nombre de usuario');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingrese un correo electrónico válido');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    final appState = context.read<AppState>();
    final cache = appState.registerCache;
    cache.username = username;
    cache.email = email;
    cache.password = password;
    await appState.saveRegisterCache();
    if (!mounted) return;
    context.go('/register/confirm');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final theme = AppTheme.of(context);
    const fieldFill = Color(0xFFE4E4E4);

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.secondary,
                foregroundColor: Colors.white,
                elevation: 2,
                expandedHeight: 130,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 52),
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Datos de Cuenta',
                      style: theme.titleSmall.copyWith(color: Colors.white),
                    ),
                  ),
                  background: Container(
                    color: theme.secondary,
                    padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Paso 3 de 4',
                            style: theme.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStepIndicator(2),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Opacity(
                  opacity: _formT.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _formT.value)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: theme.secondary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Cree sus credenciales de acceso. El proveedor será ninguno por defecto.',
                                    style: theme.bodySmall.copyWith(color: theme.primaryText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFieldWidget(
                            controller: _usernameController,
                            label: 'Nombre de Usuario *',
                            hint: 'Ej: juan123',
                            prefixIcon: Icons.alternate_email,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _emailController,
                            label: 'Correo Electrónico *',
                            hint: 'correo@ejemplo.com',
                            prefixIcon: Icons.email_outlined,
                            fillColor: fieldFill,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _passwordController,
                            label: 'Contraseña *',
                            hint: 'Mínimo 6 caracteres',
                            prefixIcon: Icons.lock_outline,
                            obscure: true,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _confirmPasswordController,
                            label: 'Confirmar Contraseña *',
                            hint: 'Repita la contraseña',
                            prefixIcon: Icons.lock_outline,
                            obscure: true,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: 'Siguiente',
                            icon: Icons.arrow_forward_ios,
                            onPressed: _saveAndNext,
                          ),
                          const SizedBox(height: 12),
                          ButtonWidget(
                            text: 'Atrás',
                            variant: ButtonVariant.outline,
                            icon: Icons.arrow_back_ios,
                            onPressed: () => context.go('/register/personal-data'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: 4,
            margin: i < 3 ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isCurrent
                  ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
