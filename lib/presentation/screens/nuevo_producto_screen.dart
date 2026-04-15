import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/proveedor_provider.dart';
import 'inventory_screen.dart'; // Reutiliza ScannerScreen

class NuevoProductoScreen extends ConsumerStatefulWidget {
  final Product? productoAEditar;

  const NuevoProductoScreen({super.key, this.productoAEditar});

  @override
  ConsumerState<NuevoProductoScreen> createState() =>
      _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends ConsumerState<NuevoProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late final TextEditingController _manualProveedorCtrl;

  String? _categoriaSeleccionada;
  String? _proveedorSeleccionado;
  bool _esProveedorManual = false;
  bool _proveedorInicializado = false;

  static const Color _accentColor = Color(0xFFEF4063);

  bool get _esEdicion => widget.productoAEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoAEditar;
    _nombreCtrl =
        TextEditingController(text: p?.nombre ?? '');
    _codigoCtrl =
        TextEditingController(text: p?.codigoBarras ?? '');
    _cantidadCtrl =
        TextEditingController(text: p != null ? p.stock.toString() : '');
    _precioCtrl = TextEditingController(
        text: p != null ? p.precio.toStringAsFixed(0) : '');
    _stockMinimoCtrl = TextEditingController(
        text: p != null ? p.stockMinimo.toString() : '5');
    _manualProveedorCtrl = TextEditingController();
    _categoriaSeleccionada = p?.categoria;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _manualProveedorCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // Generador EAN-13
  // ──────────────────────────────────────────────
  String _generarEAN13() {
    final rng = Random();
    // 12 dígitos aleatorios
    final digits = List<int>.generate(12, (_) => rng.nextInt(10));

    // Dígito de control
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    digits.add(checkDigit);

    return digits.join();
  }

  // ──────────────────────────────────────────────
  // Guardar / actualizar producto
  // ──────────────────────────────────────────────
  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final proveedorFinal = _esProveedorManual
        ? _manualProveedorCtrl.text.trim()
        : _proveedorSeleccionado!;

    final codigoFinal = _codigoCtrl.text.trim().isEmpty
        ? null
        : _codigoCtrl.text.trim();

    final producto = Product(
      id: _esEdicion ? widget.productoAEditar!.id : const Uuid().v4(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoriaSeleccionada!,
      precio: double.parse(_precioCtrl.text.trim()),
      stock: int.parse(_cantidadCtrl.text.trim()),
      codigoBarras: codigoFinal,
      proveedor: proveedorFinal,
      stockMinimo: int.parse(_stockMinimoCtrl.text.trim()),
    );

    try {
      if (_esEdicion) {
        await ref.read(productsProvider.notifier).editProduct(producto);
      } else {
        await ref.read(productsProvider.notifier).addProduct(producto);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    // Obtener lista de proveedores
    final proveedoresAsync = ref.watch(proveedoresProvider);
    final List<String> listaNombres = [];
    proveedoresAsync.whenData((list) {
      listaNombres.addAll(list.map((e) => e.empresa));
    });
    listaNombres.add('OTRO (Escribir Manualmente)');

    // Inicializar proveedor seleccionado una sola vez en modo edición
    if (_esEdicion && !_proveedorInicializado && listaNombres.length > 1) {
      _proveedorInicializado = true;
      final prov = widget.productoAEditar!.proveedor;
      if (listaNombres.contains(prov)) {
        _proveedorSeleccionado = prov;
      } else {
        _proveedorSeleccionado = 'OTRO (Escribir Manualmente)';
        _manualProveedorCtrl.text = prov;
        _esProveedorManual = true;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Producto' : 'Nuevo Producto',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── NOMBRE ─────────────────────────────────
            _InputCard(
              cardColor: cardColor,
              child: TextFormField(
                controller: _nombreCtrl,
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.w500),
                decoration: _hint('Nombre', subColor),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── CÓDIGO DE BARRAS + GENERAR ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputCard(
                    cardColor: cardColor,
                    child: TextFormField(
                      controller: _codigoCtrl,
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.w500),
                      decoration: _hint(
                        'Código de barras (EAN-13)',
                        subColor,
                        suffix: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: Colors.blueAccent),
                          tooltip: 'Escanear',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScannerScreen()),
                            );
                            if (result != null) {
                              setState(() => _codigoCtrl.text = result);
                            }
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Botón Generar
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('Generar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () =>
                        setState(() => _codigoCtrl.text = _generarEAN13()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── CANTIDAD ────────────────────────────────
            _InputCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _cantidadCtrl,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w500),
                    decoration: _hint('Cantidad', subColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'La cantidad es requerida' : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Text('Máximo 99 unidades',
                        style: TextStyle(color: subColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── PRECIO ──────────────────────────────────
            _InputCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _precioCtrl,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w500),
                    decoration: _hint('Precio', subColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'El precio es requerido' : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Text('Máximo 9,999,999',
                        style: TextStyle(color: subColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── CATEGORÍA ───────────────────────────────
            _SectionLabel('Categoría', subColor),
            _InputCard(
              cardColor: cardColor,
              child: DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor),
                decoration: _hint('', subColor),
                hint: Text('Seleccione una categoría',
                    style: TextStyle(color: subColor)),
                isExpanded: true,
                items: [
                  'Papelería',
                  'Tintas',
                  'Aseo',
                  'Dulcería',
                  'Útiles',
                  'Tecnología',
                  'Otros'
                ]
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: TextStyle(color: textColor))))
                    .toList(),
                onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                validator: (v) =>
                    v == null ? 'Seleccione una categoría' : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── STOCK MÍNIMO ────────────────────────────
            _SectionLabel('Stock Mínimo', subColor),
            _InputCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _stockMinimoCtrl,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w500),
                    decoration: _hint('', subColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Text(
                        'Alerta cuando la cantidad baje de este nivel',
                        style: TextStyle(color: subColor, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── PROVEEDOR ───────────────────────────────
            _SectionLabel('Proveedor', subColor),
            _InputCard(
              cardColor: cardColor,
              child: DropdownButtonFormField<String>(
                initialValue: listaNombres.contains(_proveedorSeleccionado)
                    ? _proveedorSeleccionado
                    : null,
                dropdownColor: cardColor,
                style: TextStyle(color: textColor),
                isExpanded: true,
                decoration: _hint('', subColor),
                hint: Text('Seleccionar proveedor',
                    style: TextStyle(color: subColor)),
                items: listaNombres
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor))))
                    .toList(),
                onChanged: (v) => setState(() {
                  _proveedorSeleccionado = v;
                  _esProveedorManual =
                      (v == 'OTRO (Escribir Manualmente)');
                }),
                validator: (v) =>
                    v == null ? 'Seleccione un proveedor' : null,
              ),
            ),

            // ── PROVEEDOR MANUAL ────────────────────────
            if (_esProveedorManual) ...[
              const SizedBox(height: 12),
              _InputCard(
                cardColor: cardColor,
                child: TextFormField(
                  controller: _manualProveedorCtrl,
                  style: TextStyle(color: textColor),
                  decoration:
                      _hint('Escriba el nombre del proveedor', subColor),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      _esProveedorManual && (v == null || v.trim().isEmpty)
                          ? 'Escriba el nombre'
                          : null,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── BOTÓN GUARDAR ───────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                onPressed: _guardarProducto,
                child: Text(
                  _esEdicion ? 'Actualizar producto' : 'Guardar producto',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decoración minimalista sin bordes visibles (apariencia limpia dentro de la card)
  InputDecoration _hint(String label, Color subColor, {Widget? suffix}) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: subColor),
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffix,
    );
  }
}

// ── WIDGETS AUXILIARES ──────────────────────────────────────
class _InputCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;

  const _InputCard({required this.child, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
