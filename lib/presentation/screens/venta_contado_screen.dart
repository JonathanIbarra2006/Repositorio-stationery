import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/pdf_generator.dart';
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';

class VentaDeContadoScreen extends ConsumerStatefulWidget {
  const VentaDeContadoScreen({super.key});

  @override
  ConsumerState<VentaDeContadoScreen> createState() => _VentaDeContadoScreenState();
}

class _VentaDeContadoScreenState extends ConsumerState<VentaDeContadoScreen> {
  final Map<Product, int> _carrito = {};
  Product? _productoSeleccionado;
  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');

  // NUEVA VARIABLE: Para controlar el estado de carga y evitar el pantallazo rojo
  bool _procesando = false;

  double get _totalVenta {
    double total = 0;
    _carrito.forEach((p, c) => total += p.precio * c);
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta de Contado', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // USAMOS UN STACK: Permite poner cosas una encima de otra (Formulario al fondo, Cargando encima)
      body: Stack(
        children: [
          // 1. EL CONTENIDO NORMAL DE LA PANTALLA
          Column(
            children: [
              // ZONA DE SELECCIÓN
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[50],
                child: productsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const Text('Error cargando inventario'),
                  data: (productos) {
                    final productosDisponibles = productos.where((p) => p.stock > 0).toList();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Product>(
                            decoration: const InputDecoration(
                                labelText: 'Seleccionar Producto',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.search)
                            ),
                            isExpanded: true,
                            value: _productoSeleccionado,
                            // FIX IMPORTANTE: Si estamos procesando, desactivamos el dropdown para evitar el error
                            onChanged: _procesando ? null : (val) => setState(() => _productoSeleccionado = val),
                            items: productosDisponibles.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.nombre} (${p.stock}) - ${currency.format(p.precio)}', overflow: TextOverflow.ellipsis),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _cantidadCtrl,
                            enabled: !_procesando, // Desactivar si procesa
                            decoration: const InputDecoration(
                                labelText: 'Cant.',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 5),
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: _procesando ? null : _agregarAlCarrito,
                        )
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // LISTA DEL CARRITO
              Expanded(
                child: _carrito.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('Carrito Vacío', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _carrito.length,
                  itemBuilder: (ctx, i) {
                    final p = _carrito.keys.elementAt(i);
                    final cant = _carrito[p]!;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          foregroundColor: Colors.teal[800],
                          child: Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Unitario: ${currency.format(p.precio)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.format(p.precio * cant),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _procesando ? null : () => setState(() => _carrito.remove(p)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ZONA TOTAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL VENTA:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(currency.format(_totalVenta), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        icon: const Icon(Icons.check_circle, size: 28),
                        label: const Text('COBRAR Y REGISTRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        // Desactivamos el botón si ya está procesando
                        onPressed: (_carrito.isEmpty || _procesando) ? null : _procesarVenta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. CAPA DE BLOQUEO (LOADING) - ESTO EVITA EL ERROR ROJO
          if (_procesando)
            Container(
              color: Colors.black.withValues(alpha: 0.5), // Fondo oscurecido
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15)
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.teal),
                      SizedBox(height: 15),
                      Text("Procesando Venta...", style: TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _agregarAlCarrito() {
    if (_productoSeleccionado == null) return;
    final int cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (cantidad <= 0) return;

    final enCarrito = _carrito[_productoSeleccionado] ?? 0;
    if ((enCarrito + cantidad) > _productoSeleccionado!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock insuficiente. Solo quedan ${_productoSeleccionado!.stock}'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      if (_carrito.containsKey(_productoSeleccionado)) {
        _carrito[_productoSeleccionado!] = _carrito[_productoSeleccionado!]! + cantidad;
      } else {
        _carrito[_productoSeleccionado!] = cantidad;
      }
      _cantidadCtrl.text = '1';
    });
  }

  Future<void> _procesarVenta() async {
    setState(() {
      _procesando = true;
      _productoSeleccionado = null;
    });

    // Guardamos una COPIA del carrito para el recibo antes de borrarlo
    final carritoParaRecibo = Map<Product, int>.from(_carrito);
    final totalParaRecibo = _totalVenta;

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final descripcionVenta = _carrito.entries.map((e) => "${e.value}x ${e.key.nombre}").join(", ");

      // A. Descontar Inventario
      for (var entry in _carrito.entries) {
        final producto = entry.key;
        final cantidadVendida = entry.value;
        final nuevoProducto = producto.copyWith(stock: producto.stock - cantidadVendida);
        await ref.read(productsProvider.notifier).editProduct(nuevoProducto);
      }

      // B. Registrar en Caja
      final nuevaTransaccion = AppTransaction(
          id: const Uuid().v4(),
          tipo: TransactionType.ingreso,
          monto: _totalVenta,
          fecha: DateTime.now(),
          descripcion: 'Venta Contado: $descripcionVenta',
          categoria: 'Ventas Mostrador'
      );

      await ref.read(transactionsProvider.notifier).addTransaction(nuevaTransaccion);

      if (mounted) {
        // C. ÉXITO Y PREGUNTA POR RECIBO
        setState(() => _procesando = false); // Quitamos el bloqueo

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text('Venta Exitosa')]),
            content: const Text('¿Deseas generar el recibo para compartir?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Cierra diálogo
                  Navigator.pop(context); // Cierra pantalla de venta
                },
                child: const Text('No, Salir'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Ver Recibo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx); // Cierra diálogo
                  // Generamos el PDF
                  PdfGenerator.generateReceipt(carritoParaRecibo, totalParaRecibo);
                  // Limpiamos carrito y UI
                  setState(() {
                    _carrito.clear();
                    _cantidadCtrl.text = '1';
                  });
                },
              ),
            ],
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
