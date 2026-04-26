import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/product.dart';
import '../../domain/models/transaction.dart';
import '../providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';
import '../../core/utils/pdf_generator.dart';
import 'fiados_screen.dart';

class VentaDeContadoScreen extends ConsumerStatefulWidget {
  const VentaDeContadoScreen({super.key});

  @override
  ConsumerState<VentaDeContadoScreen> createState() => _VentaDeContadoScreenState();
}

class _VentaDeContadoScreenState extends ConsumerState<VentaDeContadoScreen> {
  final Map<Product, int> _carrito = {};
  Product? _productoSeleccionado;
  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');

  bool _procesando = false;
  bool _esFiado = false;
  String? _clienteIdSeleccionado;

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
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Standard KlipHeader style title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Nueva Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        Text('REGISTRO DE SALIDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  if (_carrito.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: kError),
                      onPressed: _procesando ? null : () => setState(() => _carrito.clear()),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  // Product Selection Area
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: productsAsync.when(
                      loading: () => const LinearProgressIndicator(color: kAccent),
                      error: (e, _) => const Text('Error cargando inventario', style: TextStyle(color: kError)),
                      data: (productos) {
                        final productosDisponibles = productos.where((p) => p.stock > 0).toList();
                        productosDisponibles.sort((a, b) => a.nombre.compareTo(b.nombre));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AÑADIR PRODUCTO', style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Product>(
                              decoration: _inputDecoration('Buscar producto...', Icons.search_rounded, kAccent, isDark),
                              dropdownColor: cardColor,
                              isExpanded: true,
                              initialValue: _productoSeleccionado,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kAccent),
                              style: TextStyle(color: textColor, fontSize: 16),
                              onChanged: _procesando ? null : (val) {
                                setState(() {
                                  _productoSeleccionado = val;
                                  _cantidadCtrl.text = '1';
                                });
                              },
                              items: productosDisponibles.map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.nombre} — Stock: ${p.stock}', overflow: TextOverflow.ellipsis),
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        icon: const Icon(Icons.remove_rounded, color: kError, size: 22),
                                        onPressed: _procesando ? null : _decrementarCantidad,
                                      ),
                                      Container(
                                        width: 45,
                                        alignment: Alignment.center,
                                        child: TextField(
                                          controller: _cantidadCtrl,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: textColor, 
                                            fontWeight: FontWeight.w900, 
                                            fontSize: 18
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          enabled: !_procesando,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        icon: const Icon(Icons.add_rounded, color: kSuccess, size: 22),
                                        onPressed: _procesando ? null : _incrementarCantidad,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                                      label: const Text('AÑADIR', style: TextStyle(fontWeight: FontWeight.bold)),
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

                  // Cart List
                  Expanded(
                    child: _carrito.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 64, color: subColor.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                Text('Carrito vacío', style: TextStyle(color: subColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _carrito.length,
                            itemBuilder: (ctx, i) {
                              final p = _carrito.keys.elementAt(i);
                              final cant = _carrito[p]!;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: kAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('$cant', style: const TextStyle(fontWeight: FontWeight.bold, color: kAccent, fontSize: 16)),
                                  ),
                                  title: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                                  subtitle: Text(currency.format(p.precio), style: TextStyle(color: subColor, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currency.format(p.precio * cant),
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: kError, size: 18),
                                        onPressed: _procesando ? null : () => setState(() => _carrito.remove(p)),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Checkout Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5)
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: subColor, letterSpacing: 1)),
                        Text(currency.format(_totalVenta), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _esFiado ? Colors.orange : kSuccess)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _esFiado ? Colors.orange.withValues(alpha: 0.3) : Colors.transparent),
                      ),
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          '¿Venta a crédito?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _esFiado ? Colors.orange : textColor),
                        ),
                        secondary: Icon(
                          _esFiado ? Icons.credit_card_rounded : Icons.payments_rounded,
                          color: _esFiado ? Colors.orange : subColor,
                          size: 20,
                        ),
                        value: _esFiado,
                        activeThumbColor: Colors.orange,
                        onChanged: _procesando
                            ? null
                            : (v) => setState(() {
                                  _esFiado = v;
                                  _clienteIdSeleccionado = null;
                                }),
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildClientSelector(ref, isDark, cardColor, subColor),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _carrito.isEmpty
                              ? (isDark ? Colors.white10 : Colors.grey.shade200)
                              : (_esFiado ? Colors.orange : kSuccess),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: (_carrito.isEmpty || _procesando) ? null : _procesarVenta,
                        child: _procesando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_esFiado ? Icons.save_alt_rounded : Icons.check_circle_rounded, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    _esFiado ? 'REGISTRAR CRÉDITO' : 'CONFIRMAR PAGO',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color accentColor, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      filled: true,
      fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  void _agregarAlCarrito() {
    if (_productoSeleccionado == null) return;
    final int cantidadInput = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (cantidadInput <= 0) return;

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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Producto añadido al carrito'),
        duration: Duration(milliseconds: 500),
        backgroundColor: kSuccess,
      ));
      _cantidadCtrl.text = '1';
    });
  }

  Widget _buildClientSelector(WidgetRef ref, bool isDark, Color cardColor, Color subColor) {
    final clientesAsync = ref.watch(clientesProvider);

    return clientesAsync.when(
      loading: () => const LinearProgressIndicator(color: Colors.orange),
      error: (e, stack) => const SizedBox.shrink(),
      data: (clientes) {
        if (clientes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No hay clientes registrados.', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FiadosScreen()));
                  },
                  child: const Text('Ir a Clientes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<String>(
          initialValue: _clienteIdSeleccionado,
          dropdownColor: cardColor,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: _inputDecoration('Seleccionar cliente *', Icons.person_outline_rounded, Colors.orange, isDark),
          hint: Text('Selecciona un cliente', style: TextStyle(color: subColor, fontSize: 14)),
          isExpanded: true,
          items: clientes
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nombre),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _clienteIdSeleccionado = v),
        );
      },
    );
  }

  Future<void> _procesarVenta() async {
    if (_esFiado && _clienteIdSeleccionado == null) {
      _mostrarError('Selecciona un cliente para el crédito');
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
        await ref.read(clientesProvider.notifier).registrarFiado(
              clienteIdExistente: _clienteIdSeleccionado,
              carrito: _carrito,
              totalDeuda: _totalVenta,
            );
        ref.invalidate(productsProvider);

        if (mounted) {
          setState(() {
            _procesando = false;
            _carrito.clear();
            _esFiado = false;
            _clienteIdSeleccionado = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Fiado registrado correctamente'),
            ]),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context);
        }
      } else {
        final fecha = DateTime.now();
        final descripcionVenta = _carrito.entries.map((e) => '${e.value}x ${e.key.nombre}').join(', ');

        for (var entry in _carrito.entries) {
          final nuevoProducto = entry.key.copyWith(stock: entry.key.stock - entry.value);
          await ref.read(productsProvider.notifier).editProduct(nuevoProducto);
        }

        final nuevaTransaccion = AppTransaction(
            id: const Uuid().v4(),
            tipo: TransactionType.ingreso,
            monto: _totalVenta,
            fecha: fecha,
            descripcion: 'Venta Contado: $descripcionVenta',
            categoria: 'Ventas Mostrador',
            clienteId: _clienteIdSeleccionado);

        await ref.read(transactionsProvider.notifier).addTransaction(nuevaTransaccion);

        if (mounted) {
          setState(() => _procesando = false);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(children: [
                const Icon(Icons.check_circle_rounded, color: kSuccess, size: 30),
                const SizedBox(width: 12),
                Text('Venta Exitosa', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))
              ]),
              content: const Text('¿Deseas generar el recibo de esta venta?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text('No, Salir', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Ver Recibo'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    PdfGenerator.generateReceipt(carritoParaRecibo, totalParaRecibo);
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
      backgroundColor: kError,
      behavior: SnackBarBehavior.floating,
    ));
  }
}