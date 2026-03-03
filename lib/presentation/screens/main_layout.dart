import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos TODAS las pantallas
import 'home_screen.dart';       // <--- NUEVA
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

  // LISTA ACTUALIZADA DE PANTALLAS (5 Pantallas)
  // Nota: Quitamos _SettingsView de aquí porque ya lo movimos arriba
  final List<Widget> _screens = const [
    HomeScreen(),        // 0. Inicio
    FinanceScreen(),     // 1. Caja
    InventoryScreen(),   // 2. Inventario
    ProveedoresScreen(), // 3. Proveedores
    FiadosScreen(),      // 4. Fiados
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos IndexedStack para mantener el estado de las pantallas
      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        // BARRA INFERIOR ACTUALIZADA (Sin Ajustes)
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'
          ),
          NavigationDestination(
              icon: Icon(Icons.attach_money),
              label: 'Caja'
          ),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario'
          ),
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Provee.'
          ),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Fiados'
          ),
        ],
      ),
    );
  }
}
