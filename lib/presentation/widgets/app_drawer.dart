import 'package:flutter/material.dart';
// Importa tus otras pantallas aquí si necesitas navegación (ej. proveedores_screen.dart)

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el color naranja principal de tu logo para el branding
    const Color brandOrange = Color(0xFFFF6D00); // Aproximado del logo naranja

    return Drawer(
      child: Column(
        children: [
          // --- ENCABEZADO CON TU LOGO ---
          DrawerHeader(
            decoration: const BoxDecoration(
              color: brandOrange, // Fondo naranja corporativo
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tu logo centrado, ajustamos altura para que no sature
                  Image.asset(
                    'assets/images/logo.png',
                    height: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Punto de Venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- OPCIONES DE NAVEGACIÓN ---
          ListTile(
            leading: const Icon(Icons.dashboard, color: brandOrange),
            title: const Text('Dashboard'),
            onTap: () {
              // Navegar a Dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: brandOrange),
            title: const Text('Proveedores'),
            onTap: () {
              // Navegar a Proveedores (ej. Navigator.pushReplacement)
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: brandOrange),
            title: const Text('Clientes / Fiados'),
            onTap: () {
              // Navegar a Clientes
            },
          ),
          const Divider(), // Línea separadora
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              // Navegar a Configuración
            },
          ),
        ],
      ),
    );
  }
}