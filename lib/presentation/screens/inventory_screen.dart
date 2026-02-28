import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/proveedor_provider.dart'; // Importamos para listar proveedores

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
              onChanged: (val) => ref.read(productsProvider.notifier).loadProducts(query: val),
            ),
          ),
        ),
      ),
      body: productsState.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Inventario vacío. Agrega productos con el botón (+).'))
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                // Muestra si tiene código de barras con un icono pequeño
                leading: p.codigoBarras != null && p.codigoBarras!.isNotEmpty
                    ? const Icon(Icons.qr_code, color: Colors.black54)
                    : const Icon(Icons.inventory, color: Colors.blue),
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock: ${p.stock} | ${p.categoria}'),
                    Text('Prov: ${p.proveedor}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.format(p.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductModal(context, ref, productoAEditar: p)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, ref, p)),
                  ],
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
        onPressed: () => _showProductModal(context, ref),
      ),
    );
  }

  void _showProductModal(BuildContext context, WidgetRef ref, {Product? productoAEditar}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = productoAEditar != null;

    // Controladores y Variables
    String nombre = productoAEditar?.nombre ?? '';
    String? codigoBarras = productoAEditar?.codigoBarras;
    int stock = productoAEditar?.stock ?? 0;
    double precio = productoAEditar?.precio ?? 0;
    String categoria = productoAEditar?.categoria ?? '';

    // Lógica del Proveedor Híbrido
    String? proveedorSeleccionado = productoAEditar?.proveedor;
    bool esProveedorManual = false;
    final manualProveedorCtrl = TextEditingController();

    // Obtenemos la lista de proveedores actuales de la base de datos
    final proveedoresListAsync = ref.read(proveedoresProvider);
    List<String> listaNombresProveedores = [];

    // Extraemos solo los nombres
    proveedoresListAsync.whenData((proveedores) {
      listaNombresProveedores = proveedores.map((e) => e.empresa).toList();
    });

    // Añadimos opción manual
    listaNombresProveedores.add('OTRO (Escribir Manualmente)');

    // Si estamos editando y el proveedor NO está en la lista (ej. se borró), lo ponemos como manual
    if (esEdicion && !listaNombresProveedores.contains(proveedorSeleccionado) && proveedorSeleccionado != null) {
      proveedorSeleccionado = 'OTRO (Escribir Manualmente)';
      manualProveedorCtrl.text = productoAEditar!.proveedor;
      esProveedorManual = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // Usamos StatefulBuilder para manejar el estado interno del modal (mostrar/ocultar campo manual)
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        // 1. NOMBRE PRODUCTO
                        TextFormField(
                          initialValue: nombre,
                          decoration: const InputDecoration(labelText: 'Nombre Producto *', border: OutlineInputBorder()),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          onSaved: (v) => nombre = v!,
                        ),
                        const SizedBox(height: 10),

                        // 2. CÓDIGO DE BARRAS (OPCIONAL)
                        TextFormField(
                          initialValue: codigoBarras,
                          decoration: const InputDecoration(
                              labelText: 'Código de Barras / QR (Opcional)',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.qr_code_scanner)
                          ),
                          keyboardType: TextInputType.text,
                          onSaved: (v) => codigoBarras = (v == null || v.isEmpty) ? null : v,
                        ),
                        const SizedBox(height: 10),

                        // 3. CANTIDAD Y PRECIO (En fila)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? stock.toString() : '',
                                decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => stock = int.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? precio.toStringAsFixed(0) : '',
                                decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => precio = double.parse(v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 4. CATEGORÍA
                        DropdownButtonFormField<String>(
                          value: categoria.isNotEmpty ? categoria : null,
                          decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                          items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => categoria = v!,
                          validator: (v) => v == null ? 'Seleccione una' : null,
                        ),
                        const SizedBox(height: 10),

                        // 5. PROVEEDOR (HÍBRIDO)
                        DropdownButtonFormField<String>(
                          value: listaNombresProveedores.contains(proveedorSeleccionado) ? proveedorSeleccionado : null,
                          decoration: const InputDecoration(labelText: 'Proveedor *', border: OutlineInputBorder()),
                          isExpanded: true, // Para evitar overflow con nombres largos
                          items: listaNombresProveedores.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setModalState(() {
                              proveedorSeleccionado = v;
                              esProveedorManual = (v == 'OTRO (Escribir Manualmente)');
                            });
                          },
                          validator: (v) => v == null ? 'Seleccione proveedor' : null,
                        ),

                        // 6. CAMPO MANUAL DE PROVEEDOR (Solo aparece si selecciona OTRO)
                        if (esProveedorManual)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextFormField(
                              controller: manualProveedorCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Escriba el nombre del proveedor *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.edit)
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => esProveedorManual && (v == null || v.isEmpty) ? 'Escriba el nombre' : null,
                            ),
                          ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();

                                // Definir el proveedor final
                                String proveedorFinal = '';
                                if (esProveedorManual) {
                                  proveedorFinal = manualProveedorCtrl.text.trim();
                                } else {
                                  proveedorFinal = proveedorSeleccionado!;
                                }

                                final nuevoProd = Product(
                                  id: esEdicion ? productoAEditar!.id : const Uuid().v4(),
                                  nombre: nombre,
                                  categoria: categoria,
                                  precio: precio,
                                  stock: stock,
                                  codigoBarras: codigoBarras,
                                  proveedor: proveedorFinal,
                                );

                                try {
                                  if (esEdicion) {
                                    await ref.read(productsProvider.notifier).editProduct(nuevoProd);
                                  } else {
                                    await ref.read(productsProvider.notifier).addProduct(nuevoProd);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                                  }
                                }
                              }
                            },
                            child: Text(esEdicion ? 'Actualizar Producto' : 'Guardar Producto'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar'), content: Text('¿Borrar ${p.nombre}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () { ref.read(productsProvider.notifier).deleteProduct(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
  }
}