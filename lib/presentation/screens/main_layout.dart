import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'finance_screen.dart';
import 'inventory_screen.dart';
import 'fiados_screen.dart';
import 'proveedores_screen.dart';
import '../providers/theme_provider.dart'; // Importamos el tema

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const FinanceScreen(),
    const InventoryScreen(),
    const FiadosScreen(),
    const ProveedoresScreen(),
    const SettingsScreen(), // NUEVA PANTALLA DE AJUSTES (Índice 4)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int indice) {
          setState(() {
            _indiceActual = indice;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Caja'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Fiados'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Proveedores'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

// --- PANTALLA DE AJUSTES INTEGRADA ---
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes del Sistema')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Apariencia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Cambia el tema visual de la aplicación'),
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            value: isDarkMode,
            onChanged: (bool value) {
              // Cambiamos el estado global del tema
              ref.read(themeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Acerca de', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión de InkTrack'),
            subtitle: Text('1.1.1 - Modo Offline Activo'),
          )
        ],
      ),
    );
  }
}