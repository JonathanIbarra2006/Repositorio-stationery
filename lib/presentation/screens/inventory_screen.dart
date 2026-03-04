import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Modelos y Providers
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/proveedor_provider.dart';

// Import del archivo de ventas
import 'venta_contado_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // --- VARIABLES DE MODO OSCURO ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text('Inventario', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        foregroundColor: textColor, // Iconos del AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale, color: Colors.teal, size: 30),
            tooltip: 'Ir a Venta de Contado',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VentaDeContadoScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textColor))),
        data: (allProducts) {
          final totalProductosCount = allProducts.length;
          final stockBajoCount = allProducts.where((p) => p.stock <= 5).length;
          final valorTotalInventario = allProducts.fold(0.0, (sum, p) => sum + (p.precio * p.stock));

          final filteredList = allProducts.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.nombre.toLowerCase().contains(q) ||
                (p.codigoBarras != null && p.codigoBarras!.contains(q));
          }).toList();

          return Column(
            children: [
              // DASHBOARD
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Productos', totalProductosCount.toString(), Icons.inventory_2, Colors.blue, cardColor, textColor)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Stock Bajo', stockBajoCount.toString(), Icons.warning_amber_rounded, Colors.orange, cardColor, textColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: isDark
                                  ? [Colors.teal.shade900, Colors.teal.shade800]
                                  : [Colors.teal.shade400, Colors.teal.shade200]
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.white),
                              SizedBox(width: 10),
                              Text('VALOR TOTAL DEL INVENTARIO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(currency.format(valorTotalInventario), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // BUSCADOR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: TextStyle(color: subTextColor),
                    prefixIcon: Icon(Icons.search, color: subTextColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              const SizedBox(height: 10),

              // LISTA
              Expanded(
                child: filteredList.isEmpty
                    ? Center(child: Text('No hay productos que coincidan', style: TextStyle(color: subTextColor)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: filteredList.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredList[i];
                    final esStockBajo = p.stock <= 5;

                    return Card(
                      color: cardColor, // Color adaptable
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                  color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Icon(Icons.inventory, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                  Text(p.categoria, style: TextStyle(color: subTextColor, fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Text(currency.format(p.precio), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 15)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: esStockBajo
                                          ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade100)
                                          : (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade100),
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                      '${p.stock} un.',
                                      style: TextStyle(
                                          color: esStockBajo ? Colors.red : (isDark ? Colors.greenAccent : Colors.green[800]),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                      )
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                        icon: Icon(Icons.edit, color: subTextColor, size: 20),
                                        onPressed: () => _showProductModal(context, ref, productoAEditar: p, isDark: isDark)
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () => _confirmDelete(context, ref, p)
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () => _showProductModal(context, ref, isDark: isDark),
      ),
    );
  }

  // WIDGET TARJETA DE ESTADÍSTICA (ADAPTABLE)
  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // MODAL DE PRODUCTO (ADAPTABLE)
  void _showProductModal(BuildContext context, WidgetRef ref, {Product? productoAEditar, required bool isDark}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = productoAEditar != null;

    // Variables de color para el Modal
    final modalBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white; // Blanco en modo claro para alto contraste
    final textColor = isDark ? Colors.white : Colors.black87;
    // Borde: Gris en oscuro, Negro sólido en claro (Alto Contraste)
    final borderColor = isDark ? Colors.grey.shade600 : Colors.black;

    String nombre = productoAEditar?.nombre ?? '';
    final codigoBarrasCtrl = TextEditingController(text: productoAEditar?.codigoBarras ?? '');
    int stock = productoAEditar?.stock ?? 0;
    double precio = productoAEditar?.precio ?? 0;
    String categoria = productoAEditar?.categoria ?? '';
    String? proveedorSeleccionado = productoAEditar?.proveedor;
    bool esProveedorManual = false;
    final manualProveedorCtrl = TextEditingController();

    final proveedoresListAsync = ref.read(proveedoresProvider);
    List<String> listaNombresProveedores = [];
    proveedoresListAsync.whenData((proveedores) {
      listaNombresProveedores = proveedores.map((e) => e.empresa).toList();
    });
    listaNombresProveedores.add('OTRO (Escribir Manualmente)');

    if (esEdicion && !listaNombresProveedores.contains(proveedorSeleccionado) && proveedorSeleccionado != null) {
      proveedorSeleccionado = 'OTRO (Escribir Manualmente)';
      manualProveedorCtrl.text = productoAEditar!.proveedor;
      esProveedorManual = true;
    }

    // Input Decoration Adaptable
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: textColor),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.blueAccent : Colors.black, width: 2.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                    color: modalBgColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
                ),
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 20),
                        Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 20),

                        TextFormField(initialValue: nombre, style: TextStyle(color: textColor), decoration: inputDecoration('Nombre Producto *', Icons.edit_note), textCapitalization: TextCapitalization.sentences, validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null, onSaved: (v) => nombre = v!.trim()),
                        const SizedBox(height: 15),

                        TextFormField(controller: codigoBarrasCtrl, style: TextStyle(color: textColor), decoration: inputDecoration('Código de Barras / QR', Icons.qr_code).copyWith(suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent), onPressed: () async { final resultado = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())); if (resultado != null) { codigoBarrasCtrl.text = resultado; } })), keyboardType: TextInputType.text),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(child: TextFormField(initialValue: esEdicion ? stock.toString() : '', style: TextStyle(color: textColor), decoration: inputDecoration('Cantidad *', Icons.numbers), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Requerido' : null, onSaved: (v) => stock = int.parse(v!))),
                            const SizedBox(width: 15),
                            Expanded(child: TextFormField(initialValue: esEdicion ? precio.toStringAsFixed(0) : '', style: TextStyle(color: textColor), decoration: inputDecoration('Precio *', Icons.attach_money), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Requerido' : null, onSaved: (v) => precio = double.parse(v!))),
                          ],
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: categoria.isNotEmpty ? categoria : null,
                          dropdownColor: modalBgColor,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration('Categoría *', Icons.category),
                          items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor)))).toList(),
                          onChanged: (v) => categoria = v!,
                          validator: (v) => v == null ? 'Seleccione una' : null,
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: listaNombresProveedores.contains(proveedorSeleccionado) ? proveedorSeleccionado : null,
                          dropdownColor: modalBgColor,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration('Proveedor *', Icons.local_shipping),
                          isExpanded: true,
                          items: listaNombresProveedores.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)))).toList(),
                          onChanged: (v) { setModalState(() { proveedorSeleccionado = v; esProveedorManual = (v == 'OTRO (Escribir Manualmente)'); }); },
                          validator: (v) => v == null ? 'Seleccione proveedor' : null,
                        ),

                        if (esProveedorManual)
                          Padding(padding: const EdgeInsets.only(top: 10.0), child: TextFormField(controller: manualProveedorCtrl, style: TextStyle(color: textColor), decoration: inputDecoration('Escriba el nombre del proveedor *', Icons.edit), textCapitalization: TextCapitalization.words, validator: (v) => esProveedorManual && (v == null || v.trim().isEmpty) ? 'Escriba el nombre' : null)),

                        const SizedBox(height: 25),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { if (formKey.currentState!.validate()) { formKey.currentState!.save(); String proveedorFinal = esProveedorManual ? manualProveedorCtrl.text.trim() : proveedorSeleccionado!; String? codigoFinal = codigoBarrasCtrl.text.trim().isEmpty ? null : codigoBarrasCtrl.text.trim(); final nuevoProd = Product(id: esEdicion ? productoAEditar!.id : const Uuid().v4(), nombre: nombre, categoria: categoria, precio: precio, stock: stock, codigoBarras: codigoFinal, proveedor: proveedorFinal); try { if (esEdicion) { await ref.read(productsProvider.notifier).editProduct(nuevoProd); } else { await ref.read(productsProvider.notifier).addProduct(nuevoProd); } if (ctx.mounted) Navigator.pop(ctx); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red)); } } }, child: Text(esEdicion ? 'Actualizar Producto' : 'Guardar Producto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar'), content: Text('¿Borrar ${p.nombre}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () { ref.read(productsProvider.notifier).deleteProduct(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
  }
}

// Pantalla Scanner (No cambia, fondo negro por defecto)
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _codigoDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Escanear Código'), backgroundColor: Colors.black, foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))), backgroundColor: Colors.black, body: Stack(children: [MobileScanner(onDetect: (capture) { if (_codigoDetectado) return; for (final barcode in capture.barcodes) { if (barcode.rawValue != null) { setState(() => _codigoDetectado = true); HapticFeedback.mediumImpact(); Navigator.pop(context, barcode.rawValue); break; }}}), Center(child: Container(width: 280, height: 280, decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 3), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]))), const Center(child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 80))]));
  }
}