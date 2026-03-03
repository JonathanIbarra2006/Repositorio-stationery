import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart'; // Ajusta la ruta si es necesario

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verificamos si es modo oscuro
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          SwitchListTile(
              title: const Text('Modo Oscuro'),
              value: isDark,
              onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode)
          ),
          const Divider(),
          const ListTile(leading: Icon(Icons.info), title: Text('Versión 2.0.1')),
          const ListTile(leading: Icon(Icons.code), title: Text('Desarrollado por Jonathan Ibarra')),
        ],
      ),
    );
  }
}