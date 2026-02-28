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
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Proveedores', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: state.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No hay proveedores registrados.'))
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: const Icon(Icons.local_shipping, color: Colors.purple),
                ),
                title: Text(p.empresa, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${p.nombre}\n${p.contacto}'), // Muestra Nombre y Teléfono
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
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _modal(context, ref)
      ),
    );
  }

  void _modal(BuildContext context, WidgetRef ref, {Proveedor? p}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = p != null;

    // Variables temporales
    String empresa = p?.empresa ?? '';
    String nombre = p?.nombre ?? '';
    String telefono = '';
    String correo = '';

    // Lógica para separar teléfono y correo si estamos editando
    if (esEdicion) {
      final partes = p!.contacto.split(' | ');
      telefono = partes[0];
      if (partes.length > 1) correo = partes[1];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            // AutovalidateMode: Muestra errores en rojo apenas el usuario interactúa
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CAMPO 1: EMPRESA (OBLIGATORIO)
                TextFormField(
                  initialValue: empresa,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Empresa *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El nombre de la empresa es obligatorio';
                    return null;
                  },
                  onSaved: (val) => empresa = val!.trim(),
                ),
                const SizedBox(height: 10),

                // CAMPO 2: NOMBRE DEL ENCARGADO (RENOMBRADO Y OBLIGATORIO)
                TextFormField(
                  initialValue: nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Encargado *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El nombre del encargado es obligatorio';
                    return null;
                  },
                  onSaved: (val) => nombre = val!.trim(),
                ),
                const SizedBox(height: 10),

                // CAMPO 3: TELÉFONO (OBLIGATORIO)
                TextFormField(
                  initialValue: telefono,
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El teléfono es obligatorio';
                    if (val.length < 7) return 'Ingrese un número válido (mínimo 7 dígitos)';
                    return null;
                  },
                  onSaved: (val) => telefono = val!.trim(),
                ),
                const SizedBox(height: 10),

                // CAMPO 4: CORREO (OPCIONAL)
                TextFormField(
                  initialValue: correo,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico (Opcional)',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => correo = val?.trim() ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')
          ),
          ElevatedButton(
              onPressed: () {
                // VALIDACIÓN FINAL ANTES DE GUARDAR
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

                  if (esEdicion) {
                    ref.read(proveedoresProvider.notifier).updateProveedor(nuevo);
                  } else {
                    ref.read(proveedoresProvider.notifier).addProveedor(nuevo);
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proveedor guardado correctamente'), backgroundColor: Colors.green)
                  );
                }
              },
              child: const Text('Guardar')
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Eliminar'),
            content: Text('¿Estás seguro de eliminar a "${p.empresa}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                  onPressed: () {
                    ref.read(proveedoresProvider.notifier).deleteProveedor(p.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red))
              )
            ]
        )
    );
  }
}