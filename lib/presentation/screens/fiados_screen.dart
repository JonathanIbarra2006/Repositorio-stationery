import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fiado_provider.dart';
import 'nuevo_fiado_screen.dart';

class FiadosScreen extends ConsumerWidget {
  const FiadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deudoresAsync = ref.watch(deudoresProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Fiados y Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: deudoresAsync.when(
        data: (deudores) {
          if (deudores.isEmpty) return const Center(child: Text('No hay clientes con deuda'));
          return ListView.builder(
            itemCount: deudores.length,
            itemBuilder: (ctx, i) {
              final c = deudores[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(c['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tel: ${c['telefono'] ?? "Sin número"}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {}, // Aquí iría la navegación al detalle
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