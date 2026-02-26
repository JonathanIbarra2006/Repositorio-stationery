import 'package:flutter/material.dart';
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
    final productsState = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto o categoría...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (value) {
                // Filtra en tiempo real (HU12)
                ref.read(productsProvider.notifier).loadProducts(query: value);
              },
            ),
          ),
        ),
      ),
      body: productsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (products) {
          if (products.isEmpty) return const Center(child: Text('No se encontraron productos.'));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(product.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${product.categoria} | Stock: ${product.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.format(product.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, product),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductModal(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- MODAL PARA AGREGAR PRODUCTO ---
  void _showAddProductModal(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String categoria = '';
    double precio = 0;
    int stock = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nuevo Producto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // 1. CAMPO: NOMBRE DEL PRODUCTO (¡Aquí está de vuelta!)
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre del producto', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Debe ingresar el nombre' : null,
                onSaved: (val) => nombre = val!,
              ),
              const SizedBox(height: 10),

              // 2. CAMPO: CATEGORÍA (Menú desplegable)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                hint: const Text('Seleccione una categoría'),
                items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles de Oficina', 'Otros']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                validator: (val) => val == null || val.isEmpty ? 'Debe seleccionar una categoría' : null,
                onChanged: (val) { if (val != null) categoria = val; },
                onSaved: (val) { if (val != null) categoria = val; },
              ),
              const SizedBox(height: 10),

              // 3. CAMPOS: PRECIO Y STOCK (En una sola fila para ahorrar espacio)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Falta precio' : null,
                      onSaved: (val) => precio = double.parse(val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Stock Inicial', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Falta stock' : null,
                      onSaved: (val) => stock = int.parse(val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // BOTÓN GUARDAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: const Padding(padding: EdgeInsets.all(12.0), child: Text('Guardar Producto', style: TextStyle(fontSize: 16))),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final newProduct = Product(
                        id: const Uuid().v4(),
                        nombre: nombre.trim(),
                        categoria: categoria,
                        precio: precio,
                        stock: stock,
                      );

                      final error = await ref.read(productsProvider.notifier).addProduct(newProduct);

                      if (error != null && ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                      } else if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Producto guardado'), backgroundColor: Colors.green));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIÁLOGO DE CONFIRMACIÓN DE BORRADO ---
  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar "${product.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await ref.read(productsProvider.notifier).deleteProduct(product.id);
              if (error != null && context.mounted) {
                // HU11 Escenario 4: Bloquear eliminación y mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.orange));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}