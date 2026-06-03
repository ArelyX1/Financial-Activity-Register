import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/menu_item_widget.dart';

class NavigationMenuPage extends StatelessWidget {
  const NavigationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(context),
            Container(
              width: 1,
              color: const Color(0xFFE1E1E1),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: theme.primaryText),
                          onPressed: () => context.go('/dashboard'),
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.primary,
                          child: Text('EA', style: theme.labelSmall.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE1E1E1)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Menú', style: theme.headlineSmall.copyWith(color: theme.primaryText)),
                          const SizedBox(height: 20),
                          _buildMenuItems(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF115955),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _sidebarIcon(context, Icons.dashboard, 'Dashboard', () => context.go('/dashboard')),
          const SizedBox(height: 24),
          _sidebarIcon(context, Icons.history, 'Historial', () => context.go('/activity/history')),
          const SizedBox(height: 24),
          _sidebarIcon(context, Icons.add_box, 'Registrar', () => context.go('/activity/register')),
          const SizedBox(height: 24),
          _sidebarIcon(context, Icons.person, 'Perfil', () => context.go('/profile')),
          const SizedBox(height: 24),
          _sidebarIcon(context, Icons.settings, 'Ajustes', () => context.go('/settings')),
          const SizedBox(height: 24),
          _sidebarIcon(context, Icons.logout, 'Salir', () => context.go('/login')),
        ],
      ),
    );
  }

  Widget _sidebarIcon(BuildContext context, IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      children: [
        MenuItemWidget(
          icon: Icons.dashboard,
          label: 'Dashboard',
          selected: false,
          onTap: () => context.go('/dashboard'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: t.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('5', style: t.labelSmall.copyWith(color: Colors.white)),
          ),
        ),
        MenuItemWidget(
          icon: Icons.history,
          label: 'Historial de Actividades',
          onTap: () => context.go('/activity/history'),
        ),
        MenuItemWidget(
          icon: Icons.add_box,
          label: 'Registrar Actividad',
          onTap: () => context.go('/activity/register'),
        ),
        MenuItemWidget(
          icon: Icons.person,
          label: 'Mi Perfil',
          onTap: () => context.go('/profile'),
        ),
        MenuItemWidget(
          icon: Icons.trending_up,
          label: 'Metas',
          onTap: () {},
        ),
        const Divider(height: 24, color: Color(0xFFE1E1E1)),
        MenuItemWidget(
          icon: Icons.settings,
          label: 'Configuración',
          onTap: () => context.go('/settings'),
        ),
        MenuItemWidget(
          icon: Icons.help_outline,
          label: 'Ayuda',
          onTap: () {},
        ),
        MenuItemWidget(
          icon: Icons.logout,
          label: 'Cerrar Sesión',
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }
}
