import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../../data/repositories/transaction_repository.dart';

class VentaContadoScreen extends ConsumerStatefulWidget {
  const VentaContadoScreen({super.key});
  @override
  ConsumerState<VentaContadoScreen> createState() => _VentaContadoScreenState();
}

class _VentaContadoScreenState extends ConsumerState<VentaContadoScreen> {
  final Map<Product, int> _carrito = {};
  double get _totalVenta => _carrito.entries.fold(0, (sum, e) => sum + (e.key.precio * e.value));

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Venta Rápida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: productosAsync.when(
        data: (productos) => ListView.builder(
          itemCount: productos.length,
          itemBuilder: (ctx, i) {
            final p = productos[i];
            final cant = _carrito[p] ?? 0;
            return Card(
              child: ListTile(
                title: Text(p.nombre),
                subtitle: Text('${currency.format(p.precio)} | Stock: ${p.stock - cant}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if(cant>0) IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: ()=>setState(()=> cant==1?_carrito.remove(p):_carrito[p]=cant-1)),
                  IconButton(icon: Icon(Icons.add, color: (p.stock-cant)>0?Colors.green:Colors.grey), onPressed: (p.stock-cant)>0?()=>setState(()=>_carrito[p]=cant+1):null),
                  Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: ${currency.format(_totalVenta)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: _carrito.isEmpty ? null : () async {
                final items = _carrito.entries.map((e) => {'productoId': e.key.id, 'cantidad': e.value}).toList();
                await ref.read(transactionRepoProvider).registrarVentaContado(items, _totalVenta);
                if (context.mounted) { ref.invalidate(transactionsProvider); ref.invalidate(productsProvider); Navigator.pop(context); }
              },
              child: const Text('COBRAR'),
            )
          ],
        ),
      ),
    );
  }
}