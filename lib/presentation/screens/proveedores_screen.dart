import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/proveedor.dart';
import '../providers/proveedor_provider.dart';

class ProveedoresScreen extends ConsumerWidget {
  const ProveedoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proveedoresState = ref.watch(proveedoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de Proveedores')),
      body: proveedoresState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (proveedores) {
          if (proveedores.isEmpty) return const Center(child: Text('No hay proveedores registrados.'));

          return ListView.builder(
            itemCount: proveedores.length,
            itemBuilder: (context, index) {
              final p = proveedores[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.local_shipping, color: Colors.white)),
                  title: Text(p.empresa, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Contacto: ${p.nombre} \nTel: ${p.contacto}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevoProveedor(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogoNuevoProveedor(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String empresa = '', nombre = '', contacto = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre de la Empresa'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
                onSaved: (val) => empresa = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre del Contacto (Vendedor)'),
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
                onSaved: (val) => nombre = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Requerido' : null,
                onSaved: (val) => contacto = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final nuevo = Proveedor(id: const Uuid().v4(), nombre: nombre, contacto: contacto, empresa: empresa);
                ref.read(proveedoresProvider.notifier).addProveedor(nuevo);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor guardado')));
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }
}