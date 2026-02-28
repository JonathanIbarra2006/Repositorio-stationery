import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        // --- LOGO A LA IZQUIERDA ---
        centerTitle: false,
        title: Image.asset('assets/images/logo.png', height: 35),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: 'Buscar producto...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
              onChanged: (v) => ref.read(productsProvider.notifier).loadProducts(query: v),
            ),
          ),
        ),
      ),
      body: products.when(
        data: (list) => list.isEmpty ? const Center(child: Text('Inventario vacío')) : ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Stock: ${p.stock} | ${p.categoria}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(currency.format(p.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _modal(context, p: p)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(context, p)),
                ]),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.add), onPressed: () => _modal(context)),
    );
  }

  void _modal(BuildContext context, {Product? p}) {
    // ... (Mantén tu lógica de modal de edición/creación aquí, asegurando el SingleChildScrollView)
    // Para no alargar demasiado la respuesta, usa el mismo modal corregido que te di antes.
    // Solo recuerda envolver el contenido en SingleChildScrollView.
  }

  void _delete(BuildContext context, Product p) {
    ref.read(productsProvider.notifier).deleteProduct(p.id);
  }
}