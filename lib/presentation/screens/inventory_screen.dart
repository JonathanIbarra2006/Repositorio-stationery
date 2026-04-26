import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/product.dart';
import '../providers/product_provider.dart';
import 'nuevo_producto_screen.dart';
import '../widgets/klip_header.dart';
import '../theme/app_colors.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isStockValueVisible = true;
  bool _showingInactive = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
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
            const KlipHeader(title: 'Klip', badge: 'CONTROL DE INVENTARIO'),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (allProducts) {
                  final totalProductosCount = allProducts.length;
                  final stockBajoCount = allProducts.where((p) => p.stock <= 5).length;
                  final valorTotalInventario = allProducts.fold(0.0, (sum, p) => sum + (p.precio * p.stock));

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Resumen\nInventario',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => setState(() => _showingInactive = !_showingInactive),
                                      icon: Icon(
                                        _showingInactive ? Icons.visibility : Icons.visibility_off,
                                        color: _showingInactive ? kAccent : subColor,
                                        size: 22,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => _isStockValueVisible = !_isStockValueVisible),
                                      icon: Icon(
                                        _isStockValueVisible ? Icons.analytics : Icons.analytics_outlined,
                                        color: subColor,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _StatItem(
                                  label: 'Productos',
                                  value: totalProductosCount.toString(),
                                  icon: Icons.inventory_2,
                                  color: kAccent,
                                ),
                                const SizedBox(width: 40),
                                _StatItem(
                                  label: 'Stock Bajo',
                                  value: stockBajoCount.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  color: kError,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Valor Total Stock', style: TextStyle(color: subColor, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isStockValueVisible 
                                          ? NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(valorTotalInventario) 
                                          : '***',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: kSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: kSuccess, size: 20),
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
                            height: 20,
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showingInactive ? 'Productos Desactivados' : 'Catálogo de Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (allProducts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: subColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text('No hay productos registrados', style: TextStyle(color: subColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        (() {
                          final filtered = allProducts.where((p) => p.isActive == !_showingInactive).toList();
                          if (filtered.isEmpty) {
                            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_showingInactive ? 'No hay productos desactivados.' : 'No hay productos activos.')));
                          }
                          return Column(
                            children: filtered.map((p) => _ProductCard(
                              product: p,
                              cardColor: cardColor,
                              textColor: textColor,
                              subColor: subColor,
                              onTap: () => _showProductOptions(context, p),
                            )).toList(),
                          );
                        })(),
                      ],
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoProductoScreen())),
        backgroundColor: kAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            if (p.isActive) ...[
              _MenuOption(
                icon: Icons.edit_rounded,
                label: 'Editar Producto',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NuevoProductoScreen(productoAEditar: p)));
                },
              ),
              _MenuOption(
                icon: Icons.block_rounded,
                label: 'Desactivar Producto',
                color: kError,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeactivate(context, ref, p);
                },
              ),
            ] else ...[
              _MenuOption(
                icon: Icons.check_circle_outline_rounded,
                label: 'Reactivar Producto',
                color: kSuccess,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(productsProvider.notifier).reactivateProduct(p.id);
                },
              ),
              _MenuOption(
                icon: Icons.delete_forever_rounded,
                label: 'Eliminar Definitivamente',
                color: kError,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref, p);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar definitivamente'),
        content: Text('¿Estás seguro de eliminar "${p.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProductPermanently(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: kError, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desactivar producto'),
        content: Text('¿Deseas desactivar "${p.nombre}" del sistema?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deactivateProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Desactivar', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final Color cardColor, textColor, subColor;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esStockBajo = product.stock <= 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.inventory_2, color: kAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.categoria.toUpperCase(),
                        style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRECIO', style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(
                      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(product.precio),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (esStockBajo ? kError : kSuccess).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.layers, color: esStockBajo ? kError : kSuccess, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'STOCK: ${product.stock}',
                        style: TextStyle(
                          color: esStockBajo ? kError : kSuccess,
                          fontWeight: FontWeight.w900,
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
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
