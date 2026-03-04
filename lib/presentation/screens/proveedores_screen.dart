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

    // MODO OSCURO
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text('Proveedores', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
      ),
      body: state.when(
        data: (list) => list.isEmpty
            ? Center(child: Text('No hay proveedores registrados.', style: TextStyle(color: subTextColor)))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            return Card(
              color: cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.local_shipping, color: Colors.purple.shade700),
                ),
                title: Text(p.empresa, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text('${p.nombre}\n${p.contacto}', style: TextStyle(color: subTextColor, fontSize: 13)),
                ),
                isThreeLine: true,
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _modal(context, ref, p: p, isDark: isDark)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, ref, p)),
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
          foregroundColor: Colors.white,
          onPressed: () => _modal(context, ref, isDark: isDark)
      ),
    );
  }

  void _modal(BuildContext context, WidgetRef ref, {Proveedor? p, required bool isDark}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = p != null;
    String empresa = p?.empresa ?? '';
    String nombre = p?.nombre ?? '';
    String telefono = '';
    String correo = '';

    if (esEdicion) {
      final partes = p!.contacto.split(' | ');
      telefono = partes[0];
      if (partes.length > 1) correo = partes[1];
    }

    // Colores Modal
    final modalBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.black;

    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: textColor),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 2.5)),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: modalBgColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(initialValue: empresa, style: TextStyle(color: textColor), decoration: inputDecoration('Nombre de la Empresa *', Icons.business), textCapitalization: TextCapitalization.words, validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null, onSaved: (val) => empresa = val!.trim()),
                        const SizedBox(height: 15),
                        TextFormField(initialValue: nombre, style: TextStyle(color: textColor), decoration: inputDecoration('Nombre del Encargado *', Icons.person), textCapitalization: TextCapitalization.words, validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null, onSaved: (val) => nombre = val!.trim()),
                        const SizedBox(height: 15),
                        TextFormField(initialValue: telefono, style: TextStyle(color: textColor), decoration: inputDecoration('Teléfono *', Icons.phone), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (val) => (val == null || val.trim().isEmpty || val.length < 7) ? 'Mínimo 7 dígitos' : null, onSaved: (val) => telefono = val!.trim()),
                        const SizedBox(height: 15),
                        TextFormField(initialValue: correo, style: TextStyle(color: textColor), decoration: inputDecoration('Correo (Opcional)', Icons.email).copyWith(hintText: 'ejemplo@correo.com', hintStyle: TextStyle(color: Colors.grey)), keyboardType: TextInputType.emailAddress, onSaved: (val) => correo = val?.trim() ?? ''),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), onPressed: () { if (formKey.currentState!.validate()) { formKey.currentState!.save(); String contactoFinal = telefono; if (correo.isNotEmpty) contactoFinal += ' | $correo'; final nuevo = Proveedor(id: esEdicion ? p!.id : const Uuid().v4(), nombre: nombre, contacto: contactoFinal, empresa: empresa); esEdicion ? ref.read(proveedoresProvider.notifier).updateProveedor(nuevo) : ref.read(proveedoresProvider.notifier).addProveedor(nuevo); Navigator.pop(ctx); } }, child: const Text('Guardar'))
                ],
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar'), content: Text('¿Eliminar a ${p.empresa}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () { ref.read(proveedoresProvider.notifier).deleteProveedor(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
  }
}