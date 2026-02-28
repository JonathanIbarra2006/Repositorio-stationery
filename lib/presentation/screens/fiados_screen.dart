import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inktrack/presentation/providers/cliente_provider.dart';
import 'nuevo_fiado_screen.dart'; // Pantalla de crear fiado

class FiadosScreen extends ConsumerWidget {
  const FiadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Asumiendo que tienes un provider para listar clientes con deuda
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        // --- LOGO A LA IZQUIERDA ---
        centerTitle: false,
        title: Image.asset('assets/images/logo.png', height: 35),
      ),
      body: clientesAsync.when(
        data: (clientes) {
          if (clientes.isEmpty) return const Center(child: Text('No hay clientes con deuda'));
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (ctx, i) {
              final c = clientes[i];
              // Aquí deberías calcular la deuda total del cliente
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tel: ${c.telefono ?? "Sin número"}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navegar a detalle del cliente (historial de fiados)
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
        onPressed: () {
          // Navegar a la pantalla de crear nuevo fiado
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoFiadoScreen()));
        },
      ),
    );
  }
}