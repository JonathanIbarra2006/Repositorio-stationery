import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

// Importamos todas las pantallas que ya hemos creado
import 'finance_screen.dart';
import 'inventory_screen.dart';
import 'proveedores_screen.dart';
import 'fiados_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  // Lista de pantallas controlada por el índice
  final List<Widget> _screens = const [
    FinanceScreen(),      // Índice 0: Caja
    InventoryScreen(),    // Índice 1: Inventario
    ProveedoresScreen(),  // Índice 2: Proveedores
    FiadosScreen(),       // Índice 3: Fiados / Clientes
    _SettingsView(),      // Índice 4: Ajustes (Definida abajo en este mismo archivo)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El cuerpo cambia según la pestaña seleccionada
      // Usamos IndexedStack para mantener el estado de las pantallas (que no se borren al cambiar)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Barra de Navegación Inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.attach_money),
            label: 'Caja',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Proveedores',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Fiados',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// PANTALLA DE AJUSTES (INTEGRADA EN EL MISMO ARCHIVO)
// ---------------------------------------------------------
class _SettingsView extends ConsumerWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Detectamos si el modo oscuro está activo
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        // --- LOGO INTEGRADO A LA IZQUIERDA (REQ. SENIOR) ---
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: 35, // Tamaño ajustado y elegante
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Apariencia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // Interruptor de Modo Oscuro
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Ahorrar batería y descansar la vista'),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            activeTrackColor: Colors.orange, // Color de marca al activar
            onChanged: (val) {
              ref.read(themeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Información del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión Actual'),
            subtitle: Text('1.2.0 (Release)'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Desarrollador'),
            subtitle: Text('Jonathan Ibarra'),
          ),
          const ListTile(
            leading: Icon(Icons.store),
            title: Text('Licencia'),
            subtitle: Text('InkTrack POS - Uso exclusivo'),
          ),
        ],
      ),
    );
  }
}
