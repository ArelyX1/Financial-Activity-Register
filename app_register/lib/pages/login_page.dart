import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../components/checkbox_widget.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/cajaIncasurLogo.jpg';
  static const double _logoBox = 116;
  static const double _logoStartScale = 1.9;

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _remember = false;
  bool _loading = false;
  String? _errorMessage;

  late final AnimationController _controller;
  late final Animation<double> _containerT;
  late final Animation<double> _logoT;
  late final Animation<double> _logoScaleT;
  late final Animation<double> _formT;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _containerT = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    );
    _logoT = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.95, curve: Curves.easeInOutCubic),
    );
    _logoScaleT = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
    );
    _formT = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;

    final logoEndTop = topPad + 24.0;
    final startCenterY = size.height * 0.46;
    final endCenterY = logoEndTop + _logoBox / 2;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final dy = (startCenterY - endCenterY) * (1 - _logoT.value);
          final scale = 1.0 + (_logoScaleT.value * (_logoStartScale - 1.0));
          final containerOffset = (1 - _containerT.value) * size.height;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Container(color: AppColors.primary),
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(0, containerOffset),
                  child: Container(
                    color: AppColors.secondaryBackground,
                    child: _buildForm(topPad),
                  ),
                ),
              ),
              Positioned(
                top: logoEndTop,
                left: 0,
                right: 0,
                height: _logoBox,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: Center(child: _buildLogo()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Ingrese su documento de identidad y contraseña');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiService.login(
        identificationNumber: username,
        password: password,
      );
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _loading = false;
          _errorMessage = 'Credenciales incorrectas';
        });
        return;
      }
      final canAccess = await ApiService.canAccessMobile(
        token: result.accessToken ?? '',
      );
      if (!mounted) return;
      if (!canAccess) {
        setState(() {
          _loading = false;
          _errorMessage = 'No tiene acceso a la aplicación móvil';
        });
        return;
      }
      context.read<AppState>().setSession(
            accessToken: result.accessToken ?? '',
            refreshToken: result.refreshToken ?? '',
            roles: result.roles,
            permissions: result.permissions,
            identificationNumber: username,
          );
      ApiService.configure(
        refreshToken: result.refreshToken,
        onTokensRefreshed: (access, refresh) async {
          if (mounted) {
            context.read<AppState>().updateTokens(accessToken: access, refreshToken: refresh);
          }
        },
      );
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e is ApiException ? e.message : 'Error de conexión';
      });
    }
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_logoBox * 0.16),
      child: Image.asset(
        _logoAsset,
        width: _logoBox * 0.66,
        height: _logoBox * 0.66,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildForm(double topPad) {
    final theme = AppTheme.of(context);
    const fieldFill = Color(0xFFE4E4E4);

    return Padding(
      padding: EdgeInsets.fromLTRB(28, topPad + 24 + _logoBox + 20, 28, 24),
      child: SingleChildScrollView(
        child: Opacity(
          opacity: _formT.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - _formT.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: theme.headlineMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inicia sesión para gestionar tus actividades financieras',
                  style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 28),
                TextFieldWidget(
                  controller: _userController,
                  label: 'Documento de Identidad',
                  hint: 'Ingrese su identificación (ej. DNI, RUC)',
                  prefixIcon: Icons.person_outline,
                  fillColor: fieldFill,
                ),
                const SizedBox(height: 16),
                TextFieldWidget(
                  controller: _passController,
                  label: 'Contraseña',
                  hint: 'Ingrese su contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  fillColor: fieldFill,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CheckboxWidget(
                      label: 'Recordar usuario',
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v),
                    ),
                    Flexible(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () {},
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: theme.bodySmall.copyWith(
                            color: theme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ButtonWidget(
                  text: 'Iniciar Sesión',
                  icon: Icons.login,
                  loading: _loading,
                  onPressed: _loading ? null : _login,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta?',
                      style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        'Regístrate',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
