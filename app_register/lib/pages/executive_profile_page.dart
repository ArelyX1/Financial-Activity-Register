import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/stat_card_widget.dart';
import '../components/profile_info_row_widget.dart';
import '../components/accordion_item_widget.dart';
import '../components/accordion_widget.dart';

class ExecutiveProfilePage extends StatefulWidget {
  const ExecutiveProfilePage({super.key});

  @override
  State<ExecutiveProfilePage> createState() => _ExecutiveProfilePageState();
}

class _ExecutiveProfilePageState extends State<ExecutiveProfilePage> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Mi Perfil', style: theme.titleLarge.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildStats(context),
            const SizedBox(height: 20),
            _buildInfo(context),
            const SizedBox(height: 20),
            AccordionWidget(items: [
              AccordionItemWidget(
                title: 'Últimas Actividades',
                icon: Icons.history,
                child: _buildRecentActivities(context),
              ),
              AccordionItemWidget(
                title: 'Metas y Objetivos',
                icon: Icons.track_changes,
                child: _buildGoals(context),
              ),
              AccordionItemWidget(
                title: 'Configuración',
                icon: Icons.settings,
                child: _buildSettings(context),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primary.withValues(alpha: 0.15),
            child: Text(
              'EA',
              style: theme.headlineMedium.copyWith(color: theme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text('Ejecutivo de Negocios', style: theme.bodySmall.copyWith(color: theme.secondaryText)),
          const SizedBox(height: 4),
          Text('Carlos Martínez', style: theme.titleLarge.copyWith(color: theme.primaryText)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Activo', style: theme.labelSmall.copyWith(color: theme.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: [
        StatCardWidget(title: 'Actividades', value: '48', icon: Icons.assignment),
        StatCardWidget(title: 'Clientes', value: '32', icon: Icons.people),
        StatCardWidget(title: 'Logros', value: '12', icon: Icons.emoji_events),
        StatCardWidget(title: 'Días', value: '185', icon: Icons.calendar_month),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        children: [
          ProfileInfoRowWidget(label: 'Correo', value: 'carlos.martinez@incasur.com', icon: Icons.email),
          const Divider(height: 1),
          ProfileInfoRowWidget(label: 'Teléfono', value: '+51 999 888 777', icon: Icons.phone),
          const Divider(height: 1),
          ProfileInfoRowWidget(label: 'Sucursal', value: 'Agencia Principal - Lima', icon: Icons.business),
          const Divider(height: 1),
          ProfileInfoRowWidget(label: 'Código', value: 'EJ-2024-0042', icon: Icons.badge),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final theme = AppTheme.of(context);
    final activities = ['Gestión crédito - Juan Pérez', 'Desembolso - María García', 'Consulta vehículo - Pedro López'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activities.map((a) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.circle, size: 6, color: theme.primary),
            const SizedBox(width: 10),
            Text(a, style: theme.bodyMedium.copyWith(color: theme.primaryText)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildGoals(BuildContext context) {
    return Column(
      children: [
        _goalRow(context, 'Actividades mensuales', '24/30', 0.8),
        const SizedBox(height: 12),
        _goalRow(context, 'Clientes nuevos', '12/15', 0.8),
        const SizedBox(height: 12),
        _goalRow(context, 'Desembolsos', 'S/32K / S/50K', 0.64),
      ],
    );
  }

  Widget _goalRow(BuildContext context, String label, String progress, double value) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.bodySmall.copyWith(color: theme.secondaryText)),
            Text(progress, style: theme.labelSmall.copyWith(color: theme.primaryText, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: theme.alternate,
            valueColor: AlwaysStoppedAnimation<Color>(
              value >= 0.8 ? theme.success : theme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      children: [
        _settingAction(context, 'Cambiar contraseña', Icons.lock_outline),
        const Divider(height: 1),
        _settingAction(context, 'Notificaciones', Icons.notifications_outlined),
        const Divider(height: 1),
        _settingAction(context, 'Cerrar sesión', Icons.logout),
      ],
    );
  }

  Widget _settingAction(BuildContext context, String label, IconData icon) {
    final theme = AppTheme.of(context);
    return InkWell(
      onTap: label == 'Cerrar sesión'
          ? () => context.go('/login')
          : label == 'Notificaciones'
              ? () => context.go('/settings')
              : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryText),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: theme.bodyMedium.copyWith(color: theme.primaryText))),
            Icon(Icons.chevron_right, size: 18, color: theme.secondaryText),
          ],
        ),
      ),
    );
  }
}
