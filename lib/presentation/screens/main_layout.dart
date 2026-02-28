import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inktrack/presentation/providers/theme_provider.dart';
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
  final List<Widget> _screens = const [FinanceScreen(), InventoryScreen(), ProveedoresScreen(), FiadosScreen(), _SettingsView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.attach_money), label: 'Caja'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Proveedores'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Fiados'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _SettingsView extends ConsumerWidget {
  const _SettingsView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('Modo Oscuro'), value: isDark, onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(), secondary: Icon(isDark?Icons.dark_mode:Icons.light_mode)),
          const Divider(),
          const ListTile(leading: Icon(Icons.info), title: Text('Versión 2.0.1')),
          const ListTile(leading: Icon(Icons.code), title: Text('Desarrollado por Jonathan Ibarra')),
        ],
      ),
    );
  }
}
