import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/button_widget.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class RegisterConfirmPage extends StatefulWidget {
  const RegisterConfirmPage({super.key});

  @override
  State<RegisterConfirmPage> createState() => _RegisterConfirmPageState();
}

class _RegisterConfirmPageState extends State<RegisterConfirmPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _stepMessage;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmAndRegister() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmDialog(ctx),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _stepMessage = 'Creando persona...';
    });

    final appState = context.read<AppState>();
    final cache = appState.registerCache;

    try {
      if (!mounted) return;
      setState(() => _stepMessage = 'Registrando información personal...');
      await ApiService.registerPerson(
        identificationNumber: cache.identificationNumber,
        name: cache.name,
        middleName: cache.middleName.isNotEmpty ? cache.middleName : null,
        maternalSurname: cache.maternalSurname,
        paternalSurname: cache.paternalSurname,
        birthPlaceGadm: cache.birthPlaceGadm ?? 0,
        residencePlaceGadm: cache.residencePlaceGadm ?? 0,
      );

      if (!mounted) return;
      setState(() => _stepMessage = 'Creando cuenta de usuario...');
      await ApiService.createUser(
        identificationNumber: cache.identificationNumber,
        username: cache.username,
        email: cache.email,
        password: cache.password,
        nIdAccountProvider: 1,
        providerId: '',
      );

      if (!mounted) return;
      await appState.clearRegisterCache();

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stepMessage = null;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(
            e is ApiException ? e.message : 'Error inesperado. Intente de nuevo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Registro Exitoso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Su cuenta ha sido creada. Ahora puede iniciar sesión con su documento de identidad y contraseña.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              text: 'Ir al Login',
              icon: Icons.login,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final theme = AppTheme.of(context);
    final cache = context.watch<AppState>().registerCache;

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
                      'Confirmar Registro',
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
                            'Paso 4 de 4',
                            style: theme.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStepIndicator(3),
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
                          if (_loading) ...[
                            _buildLoadingCard(theme),
                            const SizedBox(height: 24),
                          ],
                          _buildSummarySection(
                            theme,
                            'Identificación',
                            Icons.badge_outlined,
                            [
                              _summaryRow('Documento', cache.identificationNumber),
                              _summaryRow('Tipo ID', cache.idIdentificationType),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummarySection(
                            theme,
                            'Datos Personales',
                            Icons.person_outline,
                            [
                              _summaryRow('Nombre', '${cache.name} ${cache.middleName}'.trim()),
                              _summaryRow('Apellido Paterno', cache.paternalSurname),
                              _summaryRow('Apellido Materno', cache.maternalSurname),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummarySection(
                            theme,
                            'Lugar de Nacimiento',
                            Icons.location_on_outlined,
                            [
                              _summaryRow('País', cache.birthCountryName ?? '—'),
                              _summaryRow('Departamento', cache.birthRegionName ?? '—'),
                              if (cache.birthProvinceName != null)
                                _summaryRow('Provincia', cache.birthProvinceName!),
                              if (cache.birthDistrictName != null)
                                _summaryRow('Distrito', cache.birthDistrictName!),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummarySection(
                            theme,
                            'Lugar de Residencia',
                            Icons.home_outlined,
                            [
                              _summaryRow('País', cache.residenceCountryName ?? '—'),
                              _summaryRow('Departamento', cache.residenceRegionName ?? '—'),
                              if (cache.residenceProvinceName != null)
                                _summaryRow('Provincia', cache.residenceProvinceName!),
                              if (cache.residenceDistrictName != null)
                                _summaryRow('Distrito', cache.residenceDistrictName!),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSummarySection(
                            theme,
                            'Datos de Cuenta',
                            Icons.account_circle_outlined,
                            [
                              _summaryRow('Usuario', cache.username),
                              _summaryRow('Correo', cache.email),
                              _summaryRow('Proveedor', 'Ninguno'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: 'Confirmar Registro',
                            icon: Icons.check_circle_outline,
                            loading: _loading,
                            onPressed: _loading ? null : _confirmAndRegister,
                          ),
                          const SizedBox(height: 12),
                          ButtonWidget(
                            text: 'Atrás',
                            variant: ButtonVariant.outline,
                            icon: Icons.arrow_back_ios,
                            onPressed: _loading ? null : () => context.go('/register/account'),
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

  Widget _buildLoadingCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _stepMessage ?? 'Procesando...',
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    AppThemeData theme,
    String title,
    IconData icon,
    List<Widget> rows,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E1E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.secondary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.titleSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: theme.bodySmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDialog(BuildContext context) {
    final theme = AppTheme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.help_outline, color: theme.secondary, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Confirmar Datos'),
        ],
      ),
      content: Text(
        '¿Está seguro de que todos los datos son correctos? Se procederá a crear su cuenta.',
        style: theme.bodyMedium.copyWith(color: theme.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: TextStyle(color: theme.secondaryText),
          ),
        ),
        ButtonWidget(
          text: 'Confirmar',
          icon: Icons.check,
          expanded: false,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
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
