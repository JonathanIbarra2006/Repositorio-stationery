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
                  subtitle: Text('Contacto: ${p.nombre} \n${p.contacto}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProveedorModal(context, ref, proveedorAEditar: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmarEliminacion(context, ref, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProveedorModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // MODAL ADAPTADO PARA MODO HORIZONTAL (RESPONSIVO) Y EDICIÓN
  void _showProveedorModal(BuildContext context, WidgetRef ref, {Proveedor? proveedorAEditar}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = proveedorAEditar != null;

    String empresa = proveedorAEditar?.empresa ?? '';
    String nombre = proveedorAEditar?.nombre ?? '';

    // Extraemos teléfono y correo del string guardado si es edición
    String telefono = '';
    String correo = '';
    if (esEdicion && proveedorAEditar.contacto.contains(' | ')) {
      final partes = proveedorAEditar.contacto.split(' | ');
      telefono = partes[0];
      correo = partes[1];
    } else if (esEdicion) {
      telefono = proveedorAEditar.contacto;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        // SOLUCIÓN: Quitamos el Padding y dejamos solo el Scroll
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: empresa,
                  decoration: const InputDecoration(labelText: 'Nombre de la Empresa'),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Obligatorio' : null,
                  onSaved: (val) => empresa = val!,
                ),
                TextFormField(
                  initialValue: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre del Contacto'),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Obligatorio' : null,
                  onSaved: (val) => nombre = val!,
                ),
                TextFormField(
                  initialValue: telefono,
                  decoration: const InputDecoration(labelText: 'Teléfono (Obligatorio)'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) => val == null || val.length < 7 ? 'Teléfono inválido' : null,
                  onSaved: (val) => telefono = val!,
                ),
                TextFormField(
                  initialValue: correo,
                  decoration: const InputDecoration(labelText: 'Correo (Opcional)'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val)) return 'Correo inválido';
                    }
                    return null;
                  },
                  onSaved: (val) => correo = val ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          // ... (Tus botones de Cancelar y Guardar siguen igual de aquí hacia abajo)
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                String contactoFinal = telefono.trim();
                if (correo.trim().isNotEmpty) contactoFinal += ' | ${correo.trim()}';

                final proveedorModificado = Proveedor(
                    id: esEdicion ? proveedorAEditar.id : const Uuid().v4(),
                    nombre: nombre.trim(),
                    contacto: contactoFinal,
                    empresa: empresa.trim()
                );

                if (esEdicion) {
                  await ref.read(proveedoresProvider.notifier).updateProveedor(proveedorModificado);
                } else {
                  await ref.read(proveedoresProvider.notifier).addProveedor(proveedorModificado);
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(esEdicion ? 'Proveedor actualizado' : 'Proveedor guardado'),
                    backgroundColor: Colors.green,
                  ));
                }
              }
            },
            child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
          )
        ],
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text('¿Estás seguro de que deseas eliminar a "${p.empresa}" de tu directorio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(proveedoresProvider.notifier).deleteProveedor(p.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proveedor eliminado'), backgroundColor: Colors.orange));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}