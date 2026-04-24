import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/proveedor.dart';
import '../providers/proveedor_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/klip_header.dart';
import 'nuevo_proveedor_screen.dart';

class ProveedoresScreen extends ConsumerStatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  ConsumerState<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends ConsumerState<ProveedoresScreen> {
  bool _isStatsVisible = true;
  bool _showingInactive = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proveedoresProvider);
    final productsAsync = ref.watch(productsProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const KlipHeader(title: 'Klip', badge: 'PROVEEDORES'),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  int totalProductos = 0;
                  productsAsync.whenData((prods) {
                    totalProductos = prods.length;
                  });

                  final conRutaCount = list.where((p) => p.diasVisita != null && p.diasVisita!.isNotEmpty).length;

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
                              color: Colors.black.withOpacity(0.04),
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
                              children: [
                                Text(
                                  'Resumen\nProveedores',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _showingInactive = !_showingInactive),
                                      child: Icon(
                                        _showingInactive ? Icons.visibility : Icons.visibility_off,
                                        color: _showingInactive ? kAccent : subColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => setState(() => _isStatsVisible = !_isStatsVisible),
                                      child: Icon(
                                        _isStatsVisible ? Icons.analytics : Icons.analytics_outlined,
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
                                  label: 'Total',
                                  value: list.length.toString(),
                                  icon: Icons.local_shipping,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 40),
                                _StatItem(
                                  label: 'Con Ruta',
                                  value: conRutaCount.toString(),
                                  icon: Icons.alt_route,
                                  color: kAccent,
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
                                    Text('Estadísticas', style: TextStyle(color: subColor, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isStatsVisible ? totalProductos.toString() : '***',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF28C76F),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF28C76F).withOpacity(0.10), shape: BoxShape.circle),
                                  child: const Icon(Icons.trending_up, color: Color(0xFF28C76F), size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        _showingInactive ? 'Proveedores Desactivados' : 'Listado de Proveedores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _showingInactive ? Colors.grey : textColor.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (list.isEmpty)
                        _buildEmptyState(subColor)
                      else ...[
                        (() {
                          final filtered = list.where((p) => p.isActive == !_showingInactive).toList();
                          if (filtered.isEmpty) {
                             return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_showingInactive ? 'No hay proveedores desactivados.' : 'No hay proveedores activos.')));
                          }
                          return Column(
                            children: filtered.map((p) => _SupplierCard(
                              proveedor: p,
                              cardColor: cardColor,
                              textColor: textColor,
                              subColor: subColor,
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NuevoProveedorScreen(proveedorAEditar: p)),
                              ),
                              onDelete: () => _confirmDeactivate(context, ref, p),
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NuevoProveedorScreen()),
        ),
        backgroundColor: kAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: color.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No hay proveedores registrados', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desactivar Proveedor', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas desactivar a "${p.empresa}" del sistema? No aparecerá en la lista activa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(proveedoresProvider.notifier).desactivarProveedor(p.id);
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
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
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

class _SupplierCard extends ConsumerWidget {
  final Proveedor proveedor;
  final Color cardColor, textColor, subColor;
  final VoidCallback onEdit, onDelete;

  const _SupplierCard({
    required this.proveedor,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_shipping, color: kAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proveedor.empresa,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  proveedor.contacto.split(' | ')[0],
                  style: TextStyle(color: subColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (proveedor.diasVisita != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Visita: ${proveedor.diasVisita}',
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            onSelected: (v) {
              if (v == 'editar') onEdit();
              if (v == 'eliminar') onDelete();
              if (v == 'reactivar') {
                ref.read(proveedoresProvider.notifier).reactivarProveedor(proveedor.id);
              }
              if (v == 'eliminar_permanente') {
                _confirmDeletePermanently(context, ref, proveedor);
              }
            },
            itemBuilder: (_) => [
              if (proveedor.isActive) ...[
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                const PopupMenuItem(value: 'eliminar', child: Text('Desactivar', style: TextStyle(color: kAccent))),
              ] else ...[
                const PopupMenuItem(value: 'reactivar', child: Text('Reactivar', style: TextStyle(color: Colors.green))),
                const PopupMenuItem(value: 'eliminar_permanente', child: Text('Eliminar Definitivamente', style: TextStyle(color: Colors.red))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Definitivamente'),
        content: Text('¿Deseas eliminar a "${p.empresa}" permanentemente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(proveedoresProvider.notifier).eliminarProveedorPermanentemente(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
