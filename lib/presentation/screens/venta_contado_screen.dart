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
  // Mapa para guardar qué productos lleva y cuántos de cada uno
  final Map<Product, int> _carrito = {};

  // Calcula el total en tiempo real
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
      appBar: AppBar(
        // --- LOGO A LA IZQUIERDA ---
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: 35,
        ),
        backgroundColor: Colors.green, // Color distintivo para ventas
        foregroundColor: Colors.white, // Texto e iconos blancos
      ),
      body: Column(
        children: [
          // Encabezado informativo
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.green.shade50,
            width: double.infinity,
            child: const Text(
              'Toque los productos para agregar al carrito:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: productosAsync.when(
              data: (productos) => productos.isEmpty
                  ? const Center(child: Text('No hay productos en el inventario.'))
                  : ListView.builder(
                itemCount: productos.length,
                itemBuilder: (ctx, i) {
                  final p = productos[i];
                  final cantidadEnCarrito = _carrito[p] ?? 0;
                  // Calculamos si queda stock disponible
                  final stockRestante = p.stock - cantidadEnCarrito;
                  final sinStock = stockRestante <= 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      // Muestra la cantidad que lleva seleccionada
                      leading: CircleAvatar(
                        backgroundColor: cantidadEnCarrito > 0 ? Colors.green : Colors.grey[300],
                        child: Text(
                          cantidadEnCarrito > 0 ? '$cantidadEnCarrito' : '',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Stock disp: $stockRestante | ${currency.format(p.precio)}',
                        style: TextStyle(color: sinStock ? Colors.red : Colors.grey[700]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Restar
                          if (cantidadEnCarrito > 0)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  if (_carrito[p]! > 1) {
                                    _carrito[p] = _carrito[p]! - 1;
                                  } else {
                                    _carrito.remove(p);
                                  }
                                });
                              },
                            ),
                          // Botón Sumar
                          IconButton(
                            icon: Icon(
                              Icons.add_circle,
                              color: sinStock ? Colors.grey : Colors.green,
                              size: 30,
                            ),
                            onPressed: sinStock ? null : () {
                              setState(() {
                                _carrito[p] = cantidadEnCarrito + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      // --- BARRA INFERIOR DE COBRO ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -3))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total a Cobrar:', style: TextStyle(color: Colors.grey)),
                  Text(
                    currency.format(_totalVenta),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.monetization_on),
                label: const Text('COBRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _carrito.isEmpty ? null : () async {
                  // 1. Preparamos los datos para la base de datos
                  final items = _carrito.entries.map((e) => {
                    'productoId': e.key.id,
                    'cantidad': e.value,
                  }).toList();

                  // 2. Ejecutamos la transacción (Resta Stock + Suma Caja)
                  await ref.read(transactionRepoProvider).registrarVentaContado(items, _totalVenta);

                  if (context.mounted) {
                    // 3. Actualizamos toda la app
                    ref.invalidate(transactionsProvider); // Refresca Finanzas
                    ref.invalidate(productsProvider);     // Refresca Inventario

                    Navigator.pop(context); // Cierra la pantalla
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Venta registrada con éxito! 💰'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        )
                    );
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