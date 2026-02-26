import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/store_provider.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(inventoryProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.withAlpha(25),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () => cartNotifier.clearCart(),
            tooltip: 'Vaciar carrito',
          )
        ],
      ),
      // Lista de productos para agregar a la venta
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          // Verificamos si hay stock
          final isOutOfStock = product.stock <= 0;

          return ListTile(
            title: Text(product.nombre),
            subtitle: Text('Stock disponible: ${product.stock}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
              onPressed: isOutOfStock ? null : () {
                cartNotifier.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.nombre} agregado al carrito'),
                    duration: const Duration(milliseconds: 500),
                  ),
                );
              },
            ),
          );
        },
      ),

      // Barra inferior del carrito
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total a cobrar:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(
                    currencyFormat.format(cartNotifier.total),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Cobrar', style: TextStyle(fontSize: 18)),
                onPressed: cart.isEmpty ? null : () {
                  // 1. Preparamos los datos para "guardar" la venta
                  final itemsSold = cart.map((item) => {
                    'productId': item.product.id,
                    'quantity': item.quantity
                  }).toList();

                  // 2. Procesamos la venta en el repositorio (resta el stock)
                  ref.read(repositoryProvider).processSale(itemsSold);

                  // 3. Limpiamos el carrito
                  cartNotifier.clearCart();

                  // 4. Actualizamos la pantalla de inventario para que refleje el nuevo stock
                  ref.read(inventoryProvider.notifier).refresh();

                  // 5. Mostramos mensaje de éxito
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¡Venta Exitosa! 🎉'),
                      content: const Text('El inventario ha sido actualizado.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Aceptar'),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}