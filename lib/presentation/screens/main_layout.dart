import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
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

  static const _accent = Color(0xFFEF4063);

  final List<Widget> _screens = const [
    HomeScreen(),        // 0 — Inicio
    FiadosScreen(),      // 1 — Clientes
    ProveedoresScreen(), // 2 — Proveedor
    InventoryScreen(),   // 3 — Inventario
    FinanceScreen(),     // 4 — Reportes
  ];

  static const _navItems = [
    _NavItem(icon: Icons.grid_view_rounded,      activeIcon: Icons.grid_view_rounded,      label: 'Inicio'),
    _NavItem(icon: Icons.people_alt_outlined,     activeIcon: Icons.people_alt_rounded,     label: 'Clientes'),
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded, label: 'Proveedor'),
    _NavItem(icon: Icons.inventory_2_outlined,    activeIcon: Icons.inventory_2_rounded,    label: 'Inventario'),
    _NavItem(icon: Icons.bar_chart_outlined,      activeIcon: Icons.bar_chart_rounded,      label: 'Reportes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final isActive = _currentIndex == i;
              final item = _navItems[i];
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _accent.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? _accent : Colors.grey[500],
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isActive ? _accent : Colors.transparent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
