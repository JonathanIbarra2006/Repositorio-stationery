import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Modelos y Providers
import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';
import '../../core/utils/pdf_generator.dart';


class VentaDeContadoScreen extends ConsumerStatefulWidget {
  const VentaDeContadoScreen({super.key});

  @override
  ConsumerState<VentaDeContadoScreen> createState() => _VentaDeContadoScreenState();
}

class _VentaDeContadoScreenState extends ConsumerState<VentaDeContadoScreen> {
  // Estado del carrito
  final Map<Product, int> _carrito = {};
  Product? _productoSeleccionado;
  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');

  // Control de UI
  bool _procesando = false;

  // ── Venta a crédito (fiado) ──────────────────────────────────────────
  bool _esFiado = false;
  String? _clienteIdParaFiado;

  // Cálculos
  double get _totalVenta {
    double total = 0;
    _carrito.forEach((p, c) => total += p.precio * c);
    return total;
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  // Métodos de ayuda para incrementar/decrementar
  void _incrementarCantidad() {
    int actual = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (_productoSeleccionado != null) {
      if (actual < _productoSeleccionado!.stock) {
        setState(() => _cantidadCtrl.text = (actual + 1).toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No puedes superar el stock disponible'), duration: Duration(milliseconds: 500))
        );
      }
    } else {
      setState(() => _cantidadCtrl.text = (actual + 1).toString());
    }
  }

  void _decrementarCantidad() {
    int actual = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (actual > 1) {
      setState(() => _cantidadCtrl.text = (actual - 1).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // --- MODO OSCURO / ESTILOS ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    // Input styles
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.black; // Alto contraste en light

    InputDecoration inputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.tealAccent : Colors.teal, width: 2)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Nueva Venta', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          if (_carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Limpiar Carrito',
              onPressed: _procesando ? null : () => setState(() => _carrito.clear()),
            )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. ZONA DE SELECCIÓN (Panel Superior)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: productsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error cargando inventario', style: TextStyle(color: Colors.red)),
                  data: (productos) {
                    // Filtramos productos con stock > 0
                    final productosDisponibles = productos.where((p) => p.stock > 0).toList();

                    // Ordenar alfabéticamente
                    productosDisponibles.sort((a, b) => a.nombre.compareTo(b.nombre));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agregar Producto', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // DROPDOWN DE PRODUCTOS
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<Product>(
                                decoration: inputDecoration('Seleccionar...').copyWith(
                                    prefixIcon: Icon(Icons.search, color: subTextColor)
                                ),
                                dropdownColor: cardColor,
                                isExpanded: true,
                                value: _productoSeleccionado,
                                icon: Icon(Icons.arrow_drop_down, color: textColor),
                                style: TextStyle(color: textColor, fontSize: 16),
                                // Bloqueamos si procesa
                                onChanged: _procesando ? null : (val) {
                                  setState(() {
                                    _productoSeleccionado = val;
                                    _cantidadCtrl.text = '1'; // Reiniciar cantidad al cambiar
                                  });
                                },
                                items: productosDisponibles.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                      '${p.nombre}  —  Stock: ${p.stock}',
                                      style: TextStyle(color: textColor),
                                      overflow: TextOverflow.ellipsis
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // CONTROLES DE CANTIDAD
                            Container(
                              decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor, width: 1) // Borde acorde al tema
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, color: Colors.red.shade300),
                                    onPressed: _procesando ? null : _decrementarCantidad,
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: _cantidadCtrl,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(border: InputBorder.none),
                                      enabled: !_procesando,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.teal),
                                    onPressed: _procesando ? null : _incrementarCantidad,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // BOTÓN AGREGAR (Grande y llamativo)
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 2
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('AGREGAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: (_procesando || _productoSeleccionado == null) ? null : _agregarAlCarrito,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    );
                  },
                ),
              ),

              // 2. LISTA DEL CARRITO
              Expanded(
                child: _carrito.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 10),
                      Text('El carrito está vacío', style: TextStyle(color: subTextColor, fontSize: 18)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _carrito.length,
                  itemBuilder: (ctx, i) {
                    final p = _carrito.keys.elementAt(i);
                    final cant = _carrito[p]!;
                    return Card(
                      color: cardColor,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.withValues(alpha: 0.2),
                          child: Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        ),
                        title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Text(
                            '${currency.format(p.precio)} c/u',
                            style: TextStyle(color: subTextColor)
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.format(p.precio * cant),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: _procesando ? null : () => setState(() => _carrito.remove(p)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. ZONA DE PAGO (Bottom Bar)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: cardColor,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Total ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor)),
                          Text(currency.format(_totalVenta), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _esFiado ? kAccent : Colors.teal)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Toggle Fiado ────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: _esFiado ? kAccent.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _esFiado ? kAccent.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          title: Text(
                            '¿Venta a crédito (Fiado)?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _esFiado ? kAccent : textColor,
                            ),
                          ),
                          subtitle: Text(
                            _esFiado ? 'Se registrará en la cartera del cliente' : 'La venta se registrará como ingreso',
                            style: TextStyle(fontSize: 11, color: subTextColor),
                          ),
                          secondary: Icon(
                            _esFiado ? Icons.credit_card : Icons.payments_outlined,
                            color: _esFiado ? kAccent : subTextColor,
                          ),
                          value: _esFiado,
                          activeColor: kAccent,
                          onChanged: _procesando
                              ? null
                              : (v) => setState(() {
                                    _esFiado = v;
                                    _clienteIdParaFiado = null;
                                  }),
                        ),
                      ),

                      // ── Selector de cliente (si es fiado) ────────────────
                      if (_esFiado) ...[const SizedBox(height: 10), _buildClientSelector(ref, textColor, subTextColor, cardColor)],

                      const SizedBox(height: 14),

                      // ── Botón cobrar ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _carrito.isEmpty
                                  ? Colors.grey
                                  : (_esFiado ? kAccent : Colors.teal),
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
                          onPressed: (_carrito.isEmpty || _procesando) ? null : _procesarVenta,
                          child: _procesando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_esFiado ? Icons.credit_card : Icons.check_circle_outline, size: 26),
                              const SizedBox(width: 10),
                              Text(
                                _esFiado ? 'REGISTRAR FIADO' : 'COBRAR VENTA',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 4. OVERLAY DE CARGA (Para evitar errores y toques accidentales)
          if (_procesando)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.teal),
                      const SizedBox(height: 20),
                      Text("Procesando...", style: TextStyle(fontWeight: FontWeight.bold, color: textColor))
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Lógica de Agregar al Carrito (Con Validación de Stock)
  void _agregarAlCarrito() {
    if (_productoSeleccionado == null) return;
    final int cantidadInput = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (cantidadInput <= 0) return;

    // Verificar si ya está en el carrito para sumar
    final cantidadEnCarrito = _carrito[_productoSeleccionado] ?? 0;
    final stockDisponible = _productoSeleccionado!.stock;

    if ((cantidadEnCarrito + cantidadInput) > stockDisponible) {
      _mostrarError('Stock insuficiente. Disponible: $stockDisponible');
      return;
    }

    setState(() {
      if (_carrito.containsKey(_productoSeleccionado)) {
        _carrito[_productoSeleccionado!] = _carrito[_productoSeleccionado!]! + cantidadInput;
      } else {
        _carrito[_productoSeleccionado!] = cantidadInput;
      }
      // Feedback visual opcional
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Agregado: ${_productoSeleccionado!.nombre}'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.teal,
      ));

      // Resetear input
      _cantidadCtrl.text = '1';
    });
  }

  // ── Selector de cliente ────────────────────────────────────────────────
  Widget _buildClientSelector(
      WidgetRef ref, Color textColor, Color? subColor, Color cardColor) {
    final clientesAsync = ref.watch(clientesProvider);

    return clientesAsync.when(
      loading: () => const LinearProgressIndicator(color: kAccent),
      error: (_, __) => const SizedBox.shrink(),
      data: (clientes) {
        if (clientes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kAccent, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'No hay clientes registrados.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: kAccent),
                  child: const Text('Ir a Clientes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _clienteIdParaFiado,
          dropdownColor: cardColor,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Seleccionar cliente *',
            labelStyle: TextStyle(color: textColor),
            prefixIcon: const Icon(Icons.person_outline, color: kAccent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: Text('Selecciona un cliente',
              style: TextStyle(color: subColor)),
          isExpanded: true,
          items: clientes
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nombre, style: TextStyle(color: textColor)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _clienteIdParaFiado = v),
        );
      },
    );
  }

  // ── Procesar Venta ────────────────────────────────────────────────────
  Future<void> _procesarVenta() async {
    // Validar cliente si es fiado
    if (_esFiado && _clienteIdParaFiado == null) {
      _mostrarError('Selecciona un cliente para el fiado');
      return;
    }

    setState(() {
      _procesando = true;
      _productoSeleccionado = null;
    });

    final carritoParaRecibo = Map<Product, int>.from(_carrito);
    final totalParaRecibo = _totalVenta;

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (_esFiado) {
        // ── Venta a crédito: registrarFiado maneja stock + deuda ────────
        await ref.read(clientesProvider.notifier).registrarFiado(
              clienteIdExistente: _clienteIdParaFiado,
              carrito: _carrito,
              totalDeuda: _totalVenta,
            );
        ref.invalidate(productsProvider);

        if (mounted) {
          setState(() {
            _procesando = false;
            _carrito.clear();
            _esFiado = false;
            _clienteIdParaFiado = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Fiado registrado en cartera del cliente'),
            ]),
            backgroundColor: kAccent,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context);
        }
      } else {
        // ── Venta de contado ─────────────────────────────────────────────
        final fecha = DateTime.now();
        final descripcionVenta =
            _carrito.entries.map((e) => '${e.value}x ${e.key.nombre}').join(', ');

        for (var entry in _carrito.entries) {
          final nuevoProducto =
              entry.key.copyWith(stock: entry.key.stock - entry.value);
          await ref.read(productsProvider.notifier).editProduct(nuevoProducto);
        }

        final nuevaTransaccion = AppTransaction(
            id: const Uuid().v4(),
            tipo: TransactionType.ingreso,
            monto: _totalVenta,
            fecha: fecha,
            descripcion: 'Venta Contado: $descripcionVenta',
            categoria: 'Ventas Mostrador');

        await ref.read(transactionsProvider.notifier).addTransaction(nuevaTransaccion);

        if (mounted) {
          setState(() => _procesando = false);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Venta Exitosa')
              ]),
              content: const Text('¿Deseas generar el recibo?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('No, Salir'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.print),
                  label: const Text('Ver Recibo'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    PdfGenerator.generateReceipt(
                        carritoParaRecibo, totalParaRecibo);
                    setState(() => _carrito.clear());
                  },
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarError('Error procesando venta: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}