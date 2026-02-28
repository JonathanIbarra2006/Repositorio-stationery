import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fiado_provider.dart';
import 'nuevo_fiado_screen.dart';
import 'detalle_cliente_screen.dart'; // <--- ESTO ES VITAL: Importa la pantalla de detalle

class FiadosScreen extends ConsumerWidget {
  const FiadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la lista de clientes del Provider
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Fiados y Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          if (clientes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No hay clientes con deuda activa', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          // LISTA DE CLIENTES
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (ctx, i) {
              final c = clientes[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.person, color: Colors.orange)
                  ),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c.telefono != null && c.telefono!.isNotEmpty ? 'Tel: ${c.telefono}' : 'Sin teléfono'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

                  // --- AQUÍ ESTABA EL PROBLEMA ---
                  // Al tocar la tarjeta, nos lleva a la pantalla de detalle
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetalleClienteScreen(cliente: c))
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nuevo Fiado'),
        backgroundColor: Colors.orange,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoFiadoScreen())),
      ),
    );
  }
}