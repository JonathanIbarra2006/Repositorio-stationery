import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/proveedor.dart';
import '../providers/proveedor_provider.dart';

class ProveedoresScreen extends ConsumerWidget {
  const ProveedoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proveedoresProvider);

    return Scaffold(
      appBar: AppBar(
        // --- LOGO A LA IZQUIERDA ---
        centerTitle: false,
        title: Image.asset('assets/images/logo.png', height: 35),
      ),
      body: state.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                title: Text(p.empresa, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.nombre),
                trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}), // Agrega tu lógica de editar
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.add), onPressed: () {}), // Tu lógica de agregar
    );
  }
}