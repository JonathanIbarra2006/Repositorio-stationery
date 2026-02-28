import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
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
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
              onChanged: (v) => ref.read(productsProvider.notifier).loadProducts(query: v),
            ),
          ),
        ),
      ),
      body: products.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Inventario vacío. Agrega tu primer producto.'))
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Stock: ${p.stock} | ${p.categoria}'),
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.format(p.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _modal(context, ref, p: p)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(context, ref, p)),
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

  void _modal(BuildContext context, WidgetRef ref, {Product? p}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = p != null;

    String nombre = p?.nombre ?? '';
    String cat = p?.categoria ?? '';
    double precio = p?.precio ?? 0;
    int stock = p?.stock ?? 0;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction, // Validación en tiempo real
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        // VALIDACIÓN DE NOMBRE
                        TextFormField(
                          initialValue: nombre,
                          decoration: const InputDecoration(labelText: 'Nombre del Producto *', border: OutlineInputBorder()),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                            return null;
                          },
                          onSaved: (v) => nombre = v!.trim(),
                        ),
                        const SizedBox(height: 10),

                        // VALIDACIÓN DE CATEGORÍA
                        DropdownButtonFormField<String>(
                          value: cat.isNotEmpty ? cat : null,
                          decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                          items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => cat = v!,
                          validator: (v) => v == null ? 'Seleccione una categoría' : null,
                        ),
                        const SizedBox(height: 10),

                        Row(
                            children: [
                              Expanded(
                                // VALIDACIÓN DE PRECIO
                                  child: TextFormField(
                                    initialValue: esEdicion ? precio.toStringAsFixed(0) : '',
                                    decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Requerido';
                                      if (double.tryParse(v) == 0) return '> 0';
                                      return null;
                                    },
                                    onSaved: (v) => precio = double.parse(v!),
                                  )
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                // VALIDACIÓN DE STOCK
                                  child: TextFormField(
                                    initialValue: esEdicion ? stock.toString() : '',
                                    decoration: const InputDecoration(labelText: 'Stock *', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Requerido';
                                      return null;
                                    },
                                    onSaved: (v) => stock = int.parse(v!),
                                  )
                              ),
                            ]
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                final prod = Product(id: esEdicion ? p!.id : const Uuid().v4(), nombre: nombre, categoria: cat, precio: precio, stock: stock);
                                esEdicion ? ref.read(productsProvider.notifier).editProduct(prod) : ref.read(productsProvider.notifier).addProduct(prod);
                                Navigator.pop(ctx);
                              }
                            },
                            child: Text(esEdicion ? 'Actualizar' : 'Guardar Producto')
                        ),
                        const SizedBox(height: 20)
                      ]
                  ),
                )
            )
        )
    );
  }

  void _delete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar'), content: Text('¿Borrar ${p.nombre}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () { ref.read(productsProvider.notifier).deleteProduct(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
  }
}