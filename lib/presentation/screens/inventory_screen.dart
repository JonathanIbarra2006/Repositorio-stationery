import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import 'nuevo_producto_screen.dart';
import '../widgets/klip_header.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isStockValueVisible = true;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KlipHeader(title: 'Klip', badge: 'CONTROL DE INVENTARIO'),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFEF4063)),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (allProducts) {
                  final totalProductosCount = allProducts.length;
                  final stockBajoCount = allProducts.where((p) => p.stock <= 5).length;
                  final valorTotalInventario = allProducts.fold(0.0, (sum, p) => sum + (p.precio * p.stock));

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Control de\nInventario',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _isStockValueVisible = !_isStockValueVisible),
                                        child: Icon(
                                          _isStockValueVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.blueGrey.shade800,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: Color(0xFFEF4063),
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F8EE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.inventory_2,
                                                color: Color(0xFF28C76F),
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Productos',
                                              style: TextStyle(
                                                color: Color(0xFF28C76F),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          totalProductosCount.toString(),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFDE8EE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Color(0xFFEF4063),
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Stock Bajo',
                                              style: TextStyle(
                                                color: Color(0xFFEF4063),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          stockBajoCount.toString(),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(color: Colors.grey.shade100, thickness: 1.5),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Valor Stock',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isStockValueVisible ? '\$${(valorTotalInventario / 1000000).toStringAsFixed(1)}M' : '***',
                                        style: const TextStyle(
                                          color: Color(0xFF28C76F),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFDE8EE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.trending_up, color: Color(0xFFEF4063), size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4063),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Catálogo de Productos',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (allProducts.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay productos en inventario.')))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: allProducts.length,
                            itemBuilder: (ctx, i) {
                              final p = allProducts[i];
                              final esStockBajo = p.stock <= 5;
                              return GestureDetector(
                                onTap: () => _showProductOptions(context, p),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F8EE),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(Icons.inventory_2, color: Color(0xFF28C76F), size: 28),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text(p.categoria, style: const TextStyle(color: Color(0xFFEF4063), fontSize: 12, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _showProductOptions(context, p),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('PRECIO VENTA', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(p.precio)} \$',
                                                style: const TextStyle(color: Color(0xFFEF4063), fontSize: 18, fontWeight: FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: esStockBajo ? const Color(0xFFFDE8EE) : const Color(0xFFE8F8EE),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: esStockBajo ? const Color(0xFFEF4063).withOpacity(0.3) : const Color(0xFF28C76F).withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.layers_outlined, color: esStockBajo ? const Color(0xFFEF4063) : const Color(0xFF28C76F), size: 14),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'STOCK: ${p.stock}',
                                                  style: TextStyle(
                                                    color: esStockBajo ? const Color(0xFFEF4063) : const Color(0xFF28C76F),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoProductoScreen())),
        backgroundColor: const Color(0xFFEF4063),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Producto'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NuevoProductoScreen(productoAEditar: p)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Desactivar Producto'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeactivate(context, ref, p);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: const Text('Desactivar producto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas desactivar "${p.nombre}"?', style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text('No aparecerá en el listado ni en nuevas ventas, pero sus registros históricos se conservarán.', style: TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFFEF4063), fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deactivateProduct(p.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4063), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: const Text('Desactivar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

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
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_codigoDetectado) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _codigoDetectado = true);
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 3), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]),
            ),
          ),
          const Center(child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 80)),
        ],
      ),
    );
  }
}
