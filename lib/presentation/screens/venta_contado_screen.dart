import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  ConsumerState<VentaDeContadoScreen> createState() =>
      _VentaDeContadoScreenState();
}

class _VentaDeContadoScreenState
    extends ConsumerState<VentaDeContadoScreen> {
  final Map<Product, int> _carrito = {};
  Product? _productoSeleccionado;
  final TextEditingController _cantidadCtrl =
      TextEditingController(text: '1');

  bool _procesando = false;

  // ── Estado de venta fiada ──────────────────────────────────
  bool _esFiado = false;
  Cliente? _clienteFiado;

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
          const SnackBar(
            content: Text('No puedes superar el stock disponible'),
            duration: Duration(milliseconds: 500),
          ),
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
    final clientesAsync = ref.watch(clientesProvider);
    final currency =
        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Nueva Venta',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor)),
                        Text('REGISTRO DE SALIDA',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kAccent,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  if (_carrito.isNotEmpty)
                    IconButton(
                      icon:
                          const Icon(Icons.delete_sweep_rounded, color: kError),
                      onPressed: _procesando
                          ? null
                          : () => setState(() => _carrito.clear()),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  // ── Selector de productos ─────────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: productsAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(color: kAccent),
                      error: (e, _) => const Text('Error cargando inventario',
                          style: TextStyle(color: kError)),
                      data: (productos) {
                        final productosDisponibles =
                            productos.where((p) => p.stock > 0).toList();
                        productosDisponibles
                            .sort((a, b) => a.nombre.compareTo(b.nombre));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AÑADIR PRODUCTO',
                                style: TextStyle(
                                    color: subColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Product>(
                              decoration: _inputDecoration(
                                  'Buscar producto...',
                                  Icons.search_rounded,
                                  kAccent,
                                  isDark),
                              dropdownColor: cardColor,
                              isExpanded: true,
                              initialValue: _productoSeleccionado,
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: kAccent),
                              style:
                                  TextStyle(color: textColor, fontSize: 16),
                              onChanged: _procesando
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _productoSeleccionado = val;
                                        _cantidadCtrl.text = '1';
                                      });
                                    },
                              items: productosDisponibles
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                            '${p.nombre} — Stock: ${p.stock}',
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                        icon: const Icon(
                                            Icons.remove_rounded,
                                            color: kError,
                                            size: 22),
                                        onPressed: _procesando
                                            ? null
                                            : _decrementarCantidad,
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
                                            fontSize: 18,
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
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
                                        constraints: const BoxConstraints(
                                            minWidth: 40, minHeight: 40),
                                        icon: const Icon(Icons.add_rounded,
                                            color: kSuccess, size: 22),
                                        onPressed: _procesando
                                            ? null
                                            : _incrementarCantidad,
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
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                          Icons.add_shopping_cart_rounded,
                                          size: 20),
                                      label: const Text('AÑADIR',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      onPressed:
                                          (_procesando ||
                                                  _productoSeleccionado == null)
                                              ? null
                                              : _agregarAlCarrito,
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

                  // ── Lista del carrito ─────────────────────────
                  Expanded(
                    child: _carrito.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: subColor.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                Text('Carrito vacío',
                                    style: TextStyle(
                                        color: subColor,
                                        fontWeight: FontWeight.w600)),
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
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: kAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('$cant',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: kAccent,
                                            fontSize: 16)),
                                  ),
                                  title: Text(p.nombre,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 14)),
                                  subtitle: Text(currency.format(p.precio),
                                      style: TextStyle(
                                          color: subColor, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currency.format(p.precio * cant),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: textColor),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            color: kError, size: 18),
                                        onPressed: _procesando
                                            ? null
                                            : () => setState(
                                                () => _carrito.remove(p)),
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

            // ── Checkout Section ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: subColor,
                                  letterSpacing: 1)),
                          Text(
                            currency.format(_totalVenta),
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _esFiado ? kWarning : kSuccess),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Toggle FIADO ────────────────────────────────
                      GestureDetector(
                        onTap: _procesando
                            ? null
                            : () => setState(() {
                                  _esFiado = !_esFiado;
                                  if (!_esFiado) _clienteFiado = null;
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _esFiado
                                ? kWarning.withValues(alpha: 0.12)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.withValues(alpha: 0.07)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _esFiado
                                  ? kWarning.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _esFiado
                                      ? kWarning.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.handshake_outlined,
                                  color: _esFiado ? kWarning : subColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Venta Fiada (a Crédito)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _esFiado ? kWarning : textColor,
                                      ),
                                    ),
                                    Text(
                                      _esFiado
                                          ? 'Se registrará como deuda del cliente'
                                          : 'Toca para cambiar a venta fiada',
                                      style: TextStyle(
                                          fontSize: 11, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _esFiado,
                                onChanged: _procesando
                                    ? null
                                    : (val) => setState(() {
                                          _esFiado = val;
                                          if (!val) _clienteFiado = null;
                                        }),
                                activeTrackColor: kWarning,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Selector de cliente (solo si es fiado) ──────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _esFiado
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: clientesAsync.when(
                                  loading: () => const LinearProgressIndicator(
                                      color: kWarning),
                                  error: (e, _) => Text('Error: $e',
                                      style: const TextStyle(color: kError)),
                                  data: (clientes) {
                                    final activos = clientes
                                        .where((c) => c.isActive)
                                        .toList();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CLIENTE DEL FIADO',
                                          style: TextStyle(
                                              color: kWarning,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2),
                                        ),
                                        const SizedBox(height: 8),
                                        if (activos.isEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: kError.withValues(
                                                  alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.warning_rounded,
                                                    color: kError, size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'No hay clientes registrados.\nRegistra un cliente primero.',
                                                  style: TextStyle(
                                                      color: kError,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          DropdownButtonFormField<Cliente>(
                                            decoration: _inputDecoration(
                                                'Seleccionar cliente...',
                                                Icons.person_search_rounded,
                                                kWarning,
                                                isDark),
                                            dropdownColor: cardColor,
                                            isExpanded: true,
                                          initialValue: _clienteFiado,
                                            icon: const Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: kWarning),
                                            style: TextStyle(
                                                color: textColor, fontSize: 15),
                                            onChanged: _procesando
                                                ? null
                                                : (val) => setState(
                                                    () => _clienteFiado = val),
                                            items: activos
                                                .map((c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(
                                                        c.nombre,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      // ── Botón de confirmación ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _carrito.isEmpty
                                ? (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200)
                                : (_esFiado ? kWarning : kSuccess),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: (_carrito.isEmpty || _procesando)
                              ? null
                              : (_esFiado ? _procesarFiado : _procesarVenta),
                          child: _procesando
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _esFiado
                                          ? Icons.handshake_rounded
                                          : Icons.check_circle_rounded,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _esFiado
                                          ? 'REGISTRAR FIADO'
                                          : 'CONFIRMAR PAGO',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
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


  InputDecoration _inputDecoration(
      String label, IconData icon, Color accentColor, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: accentColor, size: 20),
      filled: true,
      fillColor: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.grey.withValues(alpha: 0.05),
      labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  void _agregarAlCarrito() {
    if (_productoSeleccionado == null) return;
    final int cantidadInput = int.tryParse(_cantidadCtrl.text) ?? 1;
    if (cantidadInput <= 0) return;

    final cantidadEnCarrito = _carrito[_productoSeleccionado] ?? 0;
    final stockDisponible = _productoSeleccionado!.stock;

    if ((cantidadEnCarrito + cantidadInput) > stockDisponible) {
      _mostrarError(
          'Stock insuficiente. Disponible: $stockDisponible');
      return;
    }

    setState(() {
      if (_carrito.containsKey(_productoSeleccionado)) {
        _carrito[_productoSeleccionado!] =
            _carrito[_productoSeleccionado!]! + cantidadInput;
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

  // ─── Procesar Venta de Contado (flujo original) ──────────────
  Future<void> _procesarVenta() async {
    setState(() {
      _procesando = true;
      _productoSeleccionado = null;
    });

    final carritoParaRecibo = Map<Product, int>.from(_carrito);
    final totalParaRecibo = _totalVenta;

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final fecha = DateTime.now();
      final descripcionVenta =
          _carrito.entries.map((e) => '${e.value}x ${e.key.nombre}').join(', ');

      for (var entry in _carrito.entries) {
        final nuevoProducto =
            entry.key.copyWith(stock: entry.key.stock - entry.value);
        await ref.read(productsProvider.notifier).editProduct(nuevoProducto);
      }

      final nuevaTransaccion = AppTransaction(
        id: _uuid(),
        tipo: TransactionType.ingreso,
        monto: _totalVenta,
        fecha: fecha,
        descripcion: 'Venta Contado: $descripcionVenta',
        categoria: 'Ventas Mostrador',
      );

      await ref
          .read(transactionsProvider.notifier)
          .addTransaction(nuevaTransaccion);

      if (mounted) {
        setState(() => _procesando = false);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: kSuccess, size: 30),
              const SizedBox(width: 12),
              Text('Venta Exitosa',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color))
            ]),
            content: const Text(
                '¿Deseas generar el recibo de esta venta?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text('No, Salir',
                    style:
                        TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.print_rounded),
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
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarError('Error procesando venta: $e');
      }
    }
  }

  // ─── Procesar Venta Fiada ─────────────────────────────────────
  Future<void> _procesarFiado() async {
    // Validar que se haya seleccionado un cliente
    if (_clienteFiado == null) {
      _mostrarError('Debes seleccionar un cliente para registrar el fiado');
      return;
    }

    setState(() {
      _procesando = true;
      _productoSeleccionado = null;
    });

    try {
      final descripcion =
          _carrito.entries.map((e) => '${e.value}x ${e.key.nombre}').join(', ');

      final carritoItems = _carrito.entries
          .map((e) => {
                'productoId': e.key.id,
                'nombre': e.key.nombre,
                'cantidad': e.value,
                'precio': e.key.precio,
              })
          .toList();

      final error = await ref.read(fiadosProvider.notifier).crearFiado(
            clienteId: _clienteFiado!.id,
            nombreCliente: _clienteFiado!.nombre,
            total: _totalVenta,
            productosDescripcion: descripcion,
            carritoItems: carritoItems,
          );

      // Refrescar inventario
      ref.invalidate(productsProvider);

      if (mounted) {
        setState(() => _procesando = false);
        if (error != null) {
          _mostrarError(error);
          return;
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(children: [
              const Icon(Icons.handshake_rounded,
                  color: kWarning, size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Fiado Registrado',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${_clienteFiado!.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(descripcion,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWarning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _carrito.clear();
                    _esFiado = false;
                    _clienteFiado = null;
                  });
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarError('Error registrando fiado: $e');
      }
    }
  }

  String _uuid() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'txn-$now';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: kError,
      behavior: SnackBarBehavior.floating,
    ));
  }
}