import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'sync_screen.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Muestra un diálogo de confirmación y luego cierra la sesión
  /// eliminando todas las rutas apiladas antes de hacerlo,
  /// para que el Navigator no quede con rutas huérfanas.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Cierra todas las rutas apiladas en el Navigator hasta la raíz.
    // Esto evita que la pantalla de ajustes quede visible después del logout.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    // Supabase actualiza el stream de auth → main.dart detecta user == null
    // y reemplaza automáticamente MainLayout por LoginScreen.
    await ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // ── Sección: Cuenta ─────────────────────────────────────────────
          const _SectionHeader(label: 'Cuenta'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.electricBlue.withValues(alpha: 0.15),
              child: const Icon(Icons.person_outline_rounded, color: AppColors.electricBlue),
            ),
            title: Text(
              user?.email ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('Sesión activa'),
          ),
          const Divider(),

          // ── Sección: Preferencias ────────────────────────────────────────
          const _SectionHeader(label: 'Preferencias'),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
            value: isDark,
            activeThumbColor: AppColors.electricBlue,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          const Divider(),

          // ── Sección: Datos y Seguridad ───────────────────────────────────
          const _SectionHeader(label: 'Datos y Seguridad'),
          ListTile(
            leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.electricBlue),
            title: const Text('Sincronización en la Nube'),
            subtitle: const Text('Subir o descargar datos de Supabase'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Sincronización'),
                    centerTitle: true,
                  ),
                  body: const SyncScreen(),
                ),
              ),
            ),
          ),
          const Divider(),

          // ── Cerrar sesión ────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const Divider(),

          // ── Sección: Acerca de ───────────────────────────────────────────
          const _SectionHeader(label: 'Acerca de'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versión 2.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Desarrollado por Jonathan Ibarra'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Encabezado de sección con estilo consistente
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
          color: AppColors.electricBlue.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}