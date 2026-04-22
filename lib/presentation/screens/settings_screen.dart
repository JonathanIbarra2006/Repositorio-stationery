import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'sync_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Preferencias', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            value: isDark,
            onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Datos y Seguridad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_rounded, color: Colors.blue),
            title: const Text('Sincronización en la Nube'),
            subtitle: const Text('Subir o descargar datos de Supabase'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Sincronización')),
                body: const SyncScreen(),
              )),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
          const Divider(),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('Versión 2.1.0')),
          const ListTile(leading: Icon(Icons.code), title: Text('Desarrollado por Jonathan Ibarra')),
        ],
      ),
    );
  }
}