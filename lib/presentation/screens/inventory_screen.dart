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

// Import del archivo con el nombre correcto
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
        error: (e, _) => Center(child: Text('Error: $e')),
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
                        Expanded(child: _buildStatCard('Total Productos', totalProductosCount.toString(), Icons.inventory_2, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Stock Bajo', stockBajoCount.toString(), Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade200]),
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
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
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
                    ? const Center(child: Text('No hay productos que coincidan', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: filteredList.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredList[i];
                    final esStockBajo = p.stock <= 5;

                    return Card(
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
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Icon(Icons.inventory, color: Colors.blue.shade700),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(p.categoria, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                                      color: esStockBajo ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                      '${p.stock} un.',
                                      style: TextStyle(
                                          color: esStockBajo ? Colors.red : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                      )
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                        onPressed: () => _showProductModal(context, ref, productoAEditar: p)
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
        onPressed: () => _showProductModal(context, ref),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MODAL DE PRODUCTO (CON BORDES NEGROS Y EN NEGRILLA)
  // ----------------------------------------------------------------------
  void _showProductModal(BuildContext context, WidgetRef ref, {Product? productoAEditar}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = productoAEditar != null;

    String nombre = productoAEditar?.nombre ?? '';
    final codigoBarrasCtrl = TextEditingController(text: productoAEditar?.codigoBarras ?? '');
    int stock = productoAEditar?.stock ?? 0;
    double precio = productoAEditar?.precio ?? 0;
    String categoria = productoAEditar?.categoria ?? '';

    String? proveedorSeleccionado = productoAEditar?.proveedor;
    bool esProveedorManual = false;
    final manualProveedorCtrl = TextEditingController();
    AutovalidateMode modoValidacion = AutovalidateMode.disabled;

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

    // ----------------------------------------------------------------
    // FUNCIÓN DE ESTILO DE ALTO CONTRASTE (NEGRO Y GRUESO)
    // ----------------------------------------------------------------
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Texto título en negrita
        prefixIcon: Icon(icon, color: Colors.black87), // Icono oscuro
        filled: true,
        fillColor: Colors.white, // Fondo blanco para máximo contraste
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

        // BORDE POR DEFECTO: Negro y visible
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)
        ),

        // BORDE HABILITADO (Sin foco): Negro sólido y grueso (1.5)
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)
        ),

        // BORDE CON FOCO (Escribiendo): Negro más grueso (2.5)
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2.5)
        ),

        // BORDE DE ERROR: Rojo pero manteniendo el grosor
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)
        ),
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
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25))
                ),
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: modoValidacion,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                        const SizedBox(height: 20),
                        Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // 1. NOMBRE
                        TextFormField(
                          initialValue: nombre,
                          decoration: inputDecoration('Nombre Producto *', Icons.edit_note),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                          onSaved: (v) => nombre = v!.trim(),
                        ),
                        const SizedBox(height: 15),

                        // 2. CÓDIGO DE BARRAS
                        TextFormField(
                          controller: codigoBarrasCtrl,
                          decoration: inputDecoration('Código de Barras / QR', Icons.qr_code).copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                                onPressed: () async {
                                  final resultado = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ScannerScreen())
                                  );
                                  if (resultado != null) {
                                    codigoBarrasCtrl.text = resultado;
                                  }
                                },
                              )
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 15),

                        // 3. CANTIDAD Y PRECIO
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? stock.toString() : '',
                                decoration: inputDecoration('Cantidad *', Icons.numbers),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => stock = int.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? precio.toStringAsFixed(0) : '',
                                decoration: inputDecoration('Precio *', Icons.attach_money),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => precio = double.parse(v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // 4. CATEGORÍA
                        DropdownButtonFormField<String>(
                          value: categoria.isNotEmpty ? categoria : null,
                          decoration: inputDecoration('Categoría *', Icons.category),
                          items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => categoria = v!,
                          validator: (v) => v == null ? 'Seleccione una' : null,
                        ),
                        const SizedBox(height: 15),

                        // 5. PROVEEDOR
                        DropdownButtonFormField<String>(
                          value: listaNombresProveedores.contains(proveedorSeleccionado) ? proveedorSeleccionado : null,
                          decoration: inputDecoration('Proveedor *', Icons.local_shipping),
                          isExpanded: true,
                          items: listaNombresProveedores.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) {
                            setModalState(() {
                              proveedorSeleccionado = v;
                              esProveedorManual = (v == 'OTRO (Escribir Manualmente)');
                            });
                          },
                          validator: (v) => v == null ? 'Seleccione proveedor' : null,
                        ),

                        if (esProveedorManual)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextFormField(
                              controller: manualProveedorCtrl,
                              decoration: inputDecoration('Escriba el nombre del proveedor *', Icons.edit),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => esProveedorManual && (v == null || v.trim().isEmpty) ? 'Escriba el nombre' : null,
                            ),
                          ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();

                                String proveedorFinal = esProveedorManual ? manualProveedorCtrl.text.trim() : proveedorSeleccionado!;
                                String? codigoFinal = codigoBarrasCtrl.text.trim().isEmpty ? null : codigoBarrasCtrl.text.trim();

                                final nuevoProd = Product(
                                  id: esEdicion ? productoAEditar!.id : const Uuid().v4(),
                                  nombre: nombre,
                                  categoria: categoria,
                                  precio: precio,
                                  stock: stock,
                                  codigoBarras: codigoFinal,
                                  proveedor: proveedorFinal,
                                );

                                try {
                                  if (esEdicion) {
                                    await ref.read(productsProvider.notifier).editProduct(nuevoProd);
                                  } else {
                                    await ref.read(productsProvider.notifier).addProduct(nuevoProd);
                                  }
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                                  }
                                }
                              } else {
                                setModalState(() {
                                  modoValidacion = AutovalidateMode.onUserInteraction;
                                });
                              }
                            },
                            child: Text(esEdicion ? 'Actualizar Producto' : 'Guardar Producto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
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
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Borrar ${p.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                ref.read(productsProvider.notifier).deleteProduct(p.id);
                Navigator.pop(ctx);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red))
          )
        ]
    ));
  }
}

// Pantalla Scanner (Intacta)
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _codigoDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_codigoDetectado) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _codigoDetectado = true);
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                Center(child: Container(width: 280, height: 280, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 3), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]),
              child: const Center(child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 80)),
            ),
          ),
          const Positioned(
            bottom: 80, left: 0, right: 0,
            child: Text("Apunta el código dentro del cuadro", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}