import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../components/config_group_widget.dart';
import '../components/setting_row_widget.dart';
import '../components/switch_component_widget.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Configuración', style: theme.titleLarge.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajustes', style: theme.headlineSmall.copyWith(color: theme.primaryText)),
            const SizedBox(height: 4),
            Text('Personaliza tu experiencia en la aplicación', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
            const SizedBox(height: 20),

            ConfigGroupWidget(
              title: 'Notificaciones',
              description: 'Gestiona las notificaciones que recibes',
              items: [
                SettingRowWidget(
                  title: 'Notificaciones Push',
                  subtitle: 'Recibe alertas en tu dispositivo',
                  icon: Icons.notifications_active,
                  trailing: SwitchComponentWidget(
                    value: appState.pushEnabled,
                    onChanged: (v) => appState.pushEnabled = v,
                  ),
                ),
                SettingRowWidget(
                  title: 'Actividad',
                  subtitle: 'Notificaciones de nuevas actividades',
                  icon: Icons.assignment,
                  trailing: SwitchComponentWidget(
                    value: appState.activityNotifications,
                    onChanged: (v) => appState.activityNotifications = v,
                  ),
                ),
                SettingRowWidget(
                  title: 'Noticias',
                  subtitle: 'Actualizaciones y comunicados',
                  icon: Icons.campaign,
                  trailing: SwitchComponentWidget(
                    value: appState.newsNotifications,
                    onChanged: (v) => appState.newsNotifications = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ConfigGroupWidget(
              title: 'Seguridad',
              description: 'Protege tu cuenta y datos',
              items: [
                SettingRowWidget(
                  title: 'Biometría',
                  subtitle: 'Acceso con huella dactilar o facial',
                  icon: Icons.fingerprint,
                  trailing: SwitchComponentWidget(
                    value: appState.biometricsEnabled,
                    onChanged: (v) => appState.biometricsEnabled = v,
                  ),
                ),
                SettingRowWidget(
                  title: 'Recordar Usuario',
                  subtitle: 'Mantener sesión iniciada',
                  icon: Icons.remember_me,
                  trailing: SwitchComponentWidget(
                    value: appState.rememberLogin,
                    onChanged: (v) => appState.rememberLogin = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ConfigGroupWidget(
              title: 'Preferencias',
              description: 'Personaliza la apariencia',
              items: [
                SettingRowWidget(
                  title: 'Modo Oscuro',
                  subtitle: 'Activar tema oscuro',
                  icon: Icons.dark_mode,
                  trailing: SwitchComponentWidget(
                    value: appState.darkModeEnabled,
                    onChanged: (v) => appState.darkModeEnabled = v,
                  ),
                ),
                SettingRowWidget(
                  title: 'Idioma',
                  subtitle: 'Español',
                  icon: Icons.language,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Cerrar Sesión',
                  style: theme.bodyMedium.copyWith(color: theme.error),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
