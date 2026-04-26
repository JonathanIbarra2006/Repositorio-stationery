import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/proveedor_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/scanner_screen.dart';

class NuevoProductoScreen extends ConsumerStatefulWidget {
  final Product? productoAEditar;

  const NuevoProductoScreen({super.key, this.productoAEditar});

  @override
  ConsumerState<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends ConsumerState<NuevoProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late final TextEditingController _manualProveedorCtrl;

  // Estado local
  String? _categoriaSeleccionada;
  String? _proveedorSeleccionado;
  bool _esProveedorManual = false;
  bool _isInitialized = false;

  bool get _esEdicion => widget.productoAEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoAEditar;
    
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _codigoCtrl = TextEditingController(text: p?.codigoBarras ?? '');
    _cantidadCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _precioCtrl = TextEditingController(text: p != null ? p.precio.toStringAsFixed(0) : '');
    _stockMinimoCtrl = TextEditingController(text: p != null ? p.stockMinimo.toString() : '5');
    _manualProveedorCtrl = TextEditingController();

    // Inicializar categoría
    const categorias = ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros'];
    if (p != null && categorias.contains(p.categoria)) {
      _categoriaSeleccionada = p.categoria;
    } else if (p != null) {
      _categoriaSeleccionada = 'Otros';
    }
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

  String _generarEAN13() {
    final rng = Random();
    final digits = List<int>.generate(12, (_) => rng.nextInt(10));
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    digits.add(checkDigit);
    return digits.join();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final proveedorFinal = _esProveedorManual 
        ? _manualProveedorCtrl.text.trim() 
        : (_proveedorSeleccionado ?? 'Sin Proveedor');

    final producto = Product(
      id: _esEdicion ? widget.productoAEditar!.id : const Uuid().v4(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoriaSeleccionada ?? 'Otros',
      precio: double.tryParse(_precioCtrl.text.trim()) ?? 0.0,
      stock: int.tryParse(_cantidadCtrl.text.trim()) ?? 0,
      codigoBarras: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
      proveedor: proveedorFinal,
      stockMinimo: int.tryParse(_stockMinimoCtrl.text.trim()) ?? 5,
    );

    try {
      String? error;
      if (_esEdicion) {
        error = await ref.read(productsProvider.notifier).editProduct(producto);
      } else {
        error = await ref.read(productsProvider.notifier).addProduct(producto);
      }

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operación exitosa'), backgroundColor: kSuccess),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: kError),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresAsync = ref.watch(proveedoresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : kNavy;

    return Scaffold(
      backgroundColor: isDark ? kNavy : kBg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('CONTROL DE INVENTARIO', 
              style: TextStyle(fontSize: 10, color: kAccent, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('DATOS BÁSICOS'),
              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre del producto *',
                icon: Icons.inventory_2_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _codigoCtrl,
                      label: 'Código de Barras (EAN-13)',
                      icon: Icons.qr_code_scanner_rounded,
                      keyboardType: TextInputType.number,
                      suffix: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: kAccent),
                        onPressed: () async {
                          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
                          if (res != null) setState(() => _codigoCtrl.text = res);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _codigoCtrl.text = _generarEAN13()),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    style: IconButton.styleFrom(backgroundColor: kAccent.withOpacity(0.1), foregroundColor: kAccent),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('PRECIOS Y STOCK'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cantidadCtrl,
                      label: 'Stock Inicial *',
                      icon: Icons.layers_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stockMinimoCtrl,
                      label: 'Stock Mínimo',
                      icon: Icons.warning_amber_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _precioCtrl,
                label: 'Precio de Venta *',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('CATEGORIZACIÓN Y PROVEEDOR'),
              _buildDropdown(
                label: 'Categoría *',
                icon: Icons.category_outlined,
                value: _categoriaSeleccionada,
                items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros'],
                onChanged: (v) => setState(() => _categoriaSeleccionada = v),
              ),
              const SizedBox(height: 16),
              
              proveedoresAsync.when(
                data: (list) {
                  final nombres = list.map((e) => e.empresa).toSet().toList();
                  const manualLabel = 'OTRO (Escribir Manualmente)';
                  if (!nombres.contains(manualLabel)) nombres.add(manualLabel);

                  // Inicializar selección si estamos editando
                  if (_esEdicion && !_isInitialized) {
                    _isInitialized = true;
                    final prov = widget.productoAEditar!.proveedor;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          if (nombres.contains(prov)) {
                            _proveedorSeleccionado = prov;
                          } else {
                            _proveedorSeleccionado = manualLabel;
                            _manualProveedorCtrl.text = prov;
                            _esProveedorManual = true;
                          }
                        });
                      }
                    });
                  }

                  return Column(
                    children: [
                      _buildDropdown(
                        label: 'Proveedor *',
                        icon: Icons.business_rounded,
                        value: nombres.contains(_proveedorSeleccionado) ? _proveedorSeleccionado : null,
                        items: nombres,
                        onChanged: (v) => setState(() {
                          _proveedorSeleccionado = v;
                          _esProveedorManual = v == manualLabel;
                        }),
                      ),
                      if (_esProveedorManual) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _manualProveedorCtrl,
                          label: 'Nombre del Proveedor',
                          icon: Icons.edit_note_rounded,
                          validator: (v) => _esProveedorManual && (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Text('Error al cargar proveedores'),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: Icon(_esEdicion ? Icons.update : Icons.save_rounded),
                  label: Text(_esEdicion ? 'ACTUALIZAR PRODUCTO' : 'GUARDAR PRODUCTO', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kNavyLighter : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : kNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kAccent),
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kNavyLighter : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : kNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
        ),
        dropdownColor: isDark ? kNavyLighter : Colors.white,
      ),
    );
  }
}
