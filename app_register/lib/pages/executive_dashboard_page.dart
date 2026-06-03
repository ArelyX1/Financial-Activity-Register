import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/stat_card_widget.dart';
import '../components/lead_card_widget.dart';
import '../components/tab_item_widget.dart';

class ExecutiveDashboardPage extends StatefulWidget {
  const ExecutiveDashboardPage({super.key});

  @override
  State<ExecutiveDashboardPage> createState() => _ExecutiveDashboardPageState();
}

class _ExecutiveDashboardPageState extends State<ExecutiveDashboardPage> {
  int _selectedTab = 0;

  final _leads = List.generate(5, (i) => {
    'name': 'Cliente ${i + 1}',
    'document': '${70000000 + i}',
    'phone': '999 ${100 + i * 11}',
    'status': ['Nuevo', 'Contactado', 'En Proceso', 'Completado'][i % 4],
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Dashboard', style: theme.titleLarge.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => context.go('/settings'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => context.go('/menu'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 20),
              _buildStatsGrid(context),
              const SizedBox(height: 20),
              _buildTabs(context),
              const SizedBox(height: 16),
              ...(_leads as List).map((lead) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LeadCardWidget(
                  name: lead['name'] as String,
                  document: lead['document'] as String?,
                  phone: lead['phone'] as String?,
                  status: lead['status'] as String?,
                  onTap: () {},
                ),
              )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/activity/register'),
        backgroundColor: theme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¡Bienvenido!', style: theme.headlineSmall.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Ejecutivo de Negocios', style: theme.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('+12% este mes', style: theme.labelMedium.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        StatCardWidget(title: 'Actividades', value: '24', icon: Icons.assignment, color: const Color(0xFF0D6B66), percentage: 12.5),
        StatCardWidget(title: 'Clientes', value: '18', icon: Icons.people, color: const Color(0xFF4A4A4A), percentage: 8.3),
        StatCardWidget(title: 'Desembolsos', value: 'S/45.2K', icon: Icons.attach_money, color: const Color(0xFFFF9800), percentage: 15.2),
        StatCardWidget(title: 'Pendientes', value: '7', icon: Icons.pending, color: const Color(0xFF7A9C9C), percentage: -3.1),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final tabs = ['Recientes', 'Pendientes', 'Completados'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TabItemWidget(
              label: e.value,
              selected: _selectedTab == e.key,
              onTap: () => setState(() => _selectedTab = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
