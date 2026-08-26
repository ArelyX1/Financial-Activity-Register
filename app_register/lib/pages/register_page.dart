import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/cajaIncasurLogo.jpg';
  static const double _logoBox = 116;

  final _docController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  late final AnimationController _controller;
  late final Animation<double> _formT;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _formT = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = context.read<AppState>();
      await appState.loadRegisterCache();
      if (appState.registerCache.identificationNumber.isNotEmpty) {
        _docController.text = appState.registerCache.identificationNumber;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _docController.dispose();
    super.dispose();
  }

  Future<void> _verifyDocument() async {
    final doc = _docController.text.trim();
    if (doc.isEmpty) {
      setState(() => _errorMessage = 'Ingrese su número de documento');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final person = await ApiService.getPerson(identificationNumber: doc);
      if (!mounted) return;
      if (person == null) {
        setState(() {
          _loading = false;
          _errorMessage = 'No se encuentra registrado en el sistema. Contacte al administrador.';
        });
        return;
      }
      if (person.isRegistered && person.username != null && person.username!.isNotEmpty) {
        setState(() {
          _loading = false;
          _errorMessage = 'Este documento ya tiene una cuenta registrada. Inicie sesión.';
        });
        return;
      }
      final appState = context.read<AppState>();
      appState.registerCache.identificationNumber = doc;
      appState.registerCache.idIdentificationType = person.idIdentificationType.toString();
      if (person.role != null && person.role!.isNotEmpty) {
        appState.registerCache.role = person.role!;
      }
      await appState.saveRegisterCache();
      if (!mounted) return;
      context.go('/register/personal-data');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e is ApiException ? e.message : 'Error de conexión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final formOpacity = _formT.value;
          final formOffset = 24 * (1 - _formT.value);
          return Stack(
            children: [
              Positioned.fill(child: Container(color: AppColors.primary)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPad + _logoBox + 40,
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: topPad + 16),
                  child: _buildLogo(),
                ),
              ),
              Positioned.fill(
                top: topPad + _logoBox + 40,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Opacity(
                    opacity: formOpacity,
                    child: Transform.translate(
                      offset: Offset(0, formOffset),
                      child: _buildForm(),
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

  Widget _buildForm() {
    final theme = AppTheme.of(context);
    const fieldFill = Color(0xFFE4E4E4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Icon(Icons.arrow_back_ios, color: theme.secondary, size: 20),
                ),
                const Spacer(),
                Text(
                  'Crear Cuenta',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Paso 1 de 4 — Verificación de identidad',
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStepIndicator(0),
            const SizedBox(height: 32),
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
                      'Ingrese su número de documento para verificar que se encuentra registrado en el sistema.',
                      style: theme.bodySmall.copyWith(color: theme.primaryText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFieldWidget(
              controller: _docController,
              label: 'Número de Documento',
              hint: 'Ej: 12345678',
              prefixIcon: Icons.badge_outlined,
              fillColor: fieldFill,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],
            ButtonWidget(
              text: 'Siguiente',
              icon: Icons.arrow_forward_ios,
              loading: _loading,
              onPressed: _loading ? null : _verifyDocument,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya tienes cuenta?',
                  style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Iniciar Sesión',
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
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    final theme = AppTheme.of(context);
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
              color: isActive ? theme.secondary : theme.secondaryText.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isCurrent
                  ? [BoxShadow(color: theme.secondary.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorBanner(String message) {
    final theme = AppTheme.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
