import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import '../providers/proveedor_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Inventario', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
              onChanged: (val) => ref.read(productsProvider.notifier).loadProducts(query: val),
            ),
          ),
        ),
      ),
      body: productsState.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Inventario vacío. Agrega productos con el botón (+).'))
            : ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: p.codigoBarras != null && p.codigoBarras!.isNotEmpty
                    ? const Icon(Icons.qr_code_2, color: Colors.black87)
                    : const Icon(Icons.inventory, color: Colors.blue),
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock: ${p.stock} | ${p.categoria}'),
                    Text('Prov: ${p.proveedor}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (p.codigoBarras != null && p.codigoBarras!.isNotEmpty)
                      Text('Cod: ${p.codigoBarras}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.format(p.precio), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductModal(context, ref, productoAEditar: p)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, ref, p)),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showProductModal(context, ref),
      ),
    );
  }

  void _showProductModal(BuildContext context, WidgetRef ref, {Product? productoAEditar}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = productoAEditar != null;

    // Variables iniciales
    String nombre = productoAEditar?.nombre ?? '';
    final codigoBarrasCtrl = TextEditingController(text: productoAEditar?.codigoBarras ?? '');
    int stock = productoAEditar?.stock ?? 0;
    double precio = productoAEditar?.precio ?? 0;
    String categoria = productoAEditar?.categoria ?? '';

    // Lógica Proveedor
    String? proveedorSeleccionado = productoAEditar?.proveedor;
    bool esProveedorManual = false;
    final manualProveedorCtrl = TextEditingController();

    // Estado local para la validación: EMPIEZA APAGADO
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // StatefulBuilder nos permite actualizar el estado SOLO del modal (para cambiar el modo de validación)
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    // AQUÍ ESTÁ EL CAMBIO CLAVE: Usamos la variable en lugar de una constante
                    autovalidateMode: modoValidacion,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        // 1. NOMBRE
                        TextFormField(
                          initialValue: nombre,
                          decoration: const InputDecoration(labelText: 'Nombre Producto *', border: OutlineInputBorder()),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                          onSaved: (v) => nombre = v!.trim(),
                        ),
                        const SizedBox(height: 10),

                        // 2. CÓDIGO DE BARRAS
                        TextFormField(
                          controller: codigoBarrasCtrl,
                          decoration: InputDecoration(
                              labelText: 'Código de Barras / QR',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
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
                        const SizedBox(height: 10),

                        // 3. CANTIDAD Y PRECIO
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? stock.toString() : '',
                                decoration: const InputDecoration(labelText: 'Cantidad *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => stock = int.parse(v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: esEdicion ? precio.toStringAsFixed(0) : '',
                                decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => precio = double.parse(v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 4. CATEGORÍA
                        DropdownButtonFormField<String>(
                          value: categoria.isNotEmpty ? categoria : null,
                          decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                          items: ['Papelería', 'Tintas', 'Aseo', 'Dulcería', 'Útiles', 'Tecnología', 'Otros']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => categoria = v!,
                          validator: (v) => v == null ? 'Seleccione una' : null,
                        ),
                        const SizedBox(height: 10),

                        // 5. PROVEEDOR
                        DropdownButtonFormField<String>(
                          value: listaNombresProveedores.contains(proveedorSeleccionado) ? proveedorSeleccionado : null,
                          decoration: const InputDecoration(labelText: 'Proveedor *', border: OutlineInputBorder()),
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
                              decoration: const InputDecoration(
                                  labelText: 'Escriba el nombre del proveedor *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.edit)
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => esProveedorManual && (v == null || v.trim().isEmpty) ? 'Escriba el nombre' : null,
                            ),
                          ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // INTENTO DE GUARDAR
                              if (formKey.currentState!.validate()) {
                                // SI ES VÁLIDO: Guardamos
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
                                // SI NO ES VÁLIDO (HAY ERRORES):
                                // Activamos el modo "onUserInteraction" para que ahora sí muestre los errores en rojo
                                // y le ayude al usuario a corregir.
                                setModalState(() {
                                  modoValidacion = AutovalidateMode.onUserInteraction;
                                });
                              }
                            },
                            child: Text(esEdicion ? 'Actualizar Producto' : 'Guardar Producto'),
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
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Eliminar'), content: Text('¿Borrar ${p.nombre}?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () { ref.read(productsProvider.notifier).deleteProduct(p.id); Navigator.pop(ctx); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red)))]));
  }
}

// -----------------------------------------------------------
// PANTALLA DE ESCÁNER (INTACTA)
// -----------------------------------------------------------
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
                  setState(() {
                    _codigoDetectado = true;
                  });
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 80),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Apunta el código dentro del cuadro",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}