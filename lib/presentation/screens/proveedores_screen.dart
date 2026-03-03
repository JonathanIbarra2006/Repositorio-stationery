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
      backgroundColor: Colors.grey[50], // Fondo suave para resaltar las tarjetas
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Proveedores', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No hay proveedores registrados.', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.local_shipping, color: Colors.purple.shade700),
                ),
                title: Text(p.empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text('${p.nombre}\n${p.contacto}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ),
                isThreeLine: true,
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _modal(context, ref, p: p)
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, p)
                      ),
                    ]
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Proveedor'),
          backgroundColor: Colors.purple,
          onPressed: () => _modal(context, ref)
      ),
    );
  }

  void _modal(BuildContext context, WidgetRef ref, {Proveedor? p}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = p != null;

    // Variables locales
    String empresa = p?.empresa ?? '';
    String nombre = p?.nombre ?? '';
    String telefono = '';
    String correo = '';

    if (esEdicion) {
      final partes = p!.contacto.split(' | ');
      telefono = partes[0];
      if (partes.length > 1) correo = partes[1];
    }

    AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

    // ESTILO ALTO CONTRASTE (NEGRO Y GRUESO)
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: Colors.white, // Aseguramos fondo blanco del diálogo
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: autovalidateMode,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: empresa,
                          decoration: inputDecoration('Nombre de la Empresa *', Icons.business),
                          textCapitalization: TextCapitalization.words,
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                          onSaved: (val) => empresa = val!.trim(),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          initialValue: nombre,
                          decoration: inputDecoration('Nombre del Encargado *', Icons.person),
                          textCapitalization: TextCapitalization.words,
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                          onSaved: (val) => nombre = val!.trim(),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          initialValue: telefono,
                          decoration: inputDecoration('Teléfono *', Icons.phone),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            if (val.length < 7) return 'Mínimo 7 dígitos';
                            return null;
                          },
                          onSaved: (val) => telefono = val!.trim(),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          initialValue: correo,
                          decoration: inputDecoration('Correo (Opcional)', Icons.email).copyWith(hintText: 'ejemplo@correo.com'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(val)) {
                                return 'Correo inválido';
                              }
                            }
                            return null;
                          },
                          onSaved: (val) => correo = val?.trim() ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          String contactoFinal = telefono;
                          if (correo.isNotEmpty) contactoFinal += ' | $correo';

                          final nuevo = Proveedor(
                              id: esEdicion ? p!.id : const Uuid().v4(),
                              nombre: nombre,
                              contacto: contactoFinal,
                              empresa: empresa
                          );

                          esEdicion
                              ? ref.read(proveedoresProvider.notifier).updateProveedor(nuevo)
                              : ref.read(proveedoresProvider.notifier).addProveedor(nuevo);

                          Navigator.pop(ctx);
                        } else {
                          setModalState(() {
                            autovalidateMode = AutovalidateMode.onUserInteraction;
                          });
                        }
                      },
                      child: const Text('Guardar')
                  )
                ],
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar a ${p.empresa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () { ref.read(proveedoresProvider.notifier).deleteProveedor(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))
        ]
    ));
  }
}