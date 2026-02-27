import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';

class VentaContadoScreen extends ConsumerStatefulWidget {
  const VentaContadoScreen({super.key});

  @override
  ConsumerState<VentaContadoScreen> createState() => _VentaContadoScreenState();
}

class _VentaContadoScreenState extends ConsumerState<VentaContadoScreen> {
  final Map<Product, int> _carrito = {};

  double get _totalVenta {
    double total = 0;
    _carrito.forEach((prod, cant) => total += prod.precio * cant);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Venta Rápida'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: productosAsync.when(
        data: (productos) => ListView.builder(
          itemCount: productos.length,
          itemBuilder: (ctx, i) {
            final p = productos[i];
            final cantidad = _carrito[p] ?? 0;
            final sinStock = (p.stock - cantidad) <= 0;

            return ListTile(
              leading: CircleAvatar(backgroundColor: cantidad > 0 ? Colors.green : Colors.grey[300], child: Text(cantidad > 0 ? '$cantidad' : '', style: const TextStyle(color: Colors.white))),
              title: Text(p.nombre),
              subtitle: Text('Stock: ${p.stock - cantidad} | ${currency.format(p.precio)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cantidad > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => setState(() { if (_carrito[p]! > 1) { _carrito[p] = _carrito[p]! - 1; } else { _carrito.remove(p); } }),
                    ),
                  IconButton(
                    icon: Icon(Icons.add_shopping_cart, color: sinStock ? Colors.grey : Colors.green),
                    onPressed: sinStock ? null : () => setState(() => _carrito[p] = cantidad + 1),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -3))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total:', style: TextStyle(color: Colors.grey)),
                  Text(currency.format(_totalVenta), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                icon: const Icon(Icons.monetization_on),
                label: const Text('Cobrar', style: TextStyle(fontSize: 18)),
                onPressed: _carrito.isEmpty ? null : () async {
                  final items = _carrito.entries.map((e) => {'productoId': e.key.id, 'cantidad': e.value}).toList();
                  await ref.read(transactionRepoProvider).registrarVentaContado(items, _totalVenta);
                  if (context.mounted) {
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(productsProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta registrada 💰'), backgroundColor: Colors.green));
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}