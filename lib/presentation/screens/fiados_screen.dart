import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';
import 'detalle_cliente_screen.dart';
import 'nuevo_cliente_screen.dart';
import '../widgets/klip_header.dart';

class FiadosScreen extends ConsumerStatefulWidget {
  const FiadosScreen({super.key});

  @override
  ConsumerState<FiadosScreen> createState() => _FiadosScreenState();
}

class _FiadosScreenState extends ConsumerState<FiadosScreen> {
  bool _showingInactive = false;
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final statsAsync = ref.watch(carteraStatsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KlipHeader(title: 'Klip', badge: 'GESTIÓN DE CLIENTES'),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (stats) => _CarteraCard(
                      stats: stats,
                      currency: currency,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                      showingInactive: _showingInactive,
                      isBalanceVisible: _isBalanceVisible,
                      onToggleInactive: () => setState(() => _showingInactive = !_showingInactive),
                      onToggleBalance: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const SizedBox(
                        width: 4,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showingInactive ? 'Clientes Desactivados' : 'Listado de Clientes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _showingInactive ? Colors.grey : textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  clientesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: kAccent)),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (clientes) {
                      final filtered = clientes.where((c) => c.isActive == !_showingInactive).toList();
                      if (filtered.isEmpty) {
                        return _EmptyClientes(subColor: subColor, showingInactive: _showingInactive);
                      }
                      return Column(
                        children: filtered
                            .map((c) => _ClienteTile(
                                  cliente: c,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subColor: subColor,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              DetalleClienteScreen(
                                                  cliente: c))),
                                  onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              NuevoClienteScreen(
                                                  clienteAEditar: c))),
                                ))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NuevoClienteScreen()),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _CarteraCard extends StatelessWidget {
  final CarteraStats stats;
  final NumberFormat currency;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool showingInactive;
  final bool isBalanceVisible;
  final VoidCallback onToggleInactive;
  final VoidCallback onToggleBalance;

  const _CarteraCard({
    required this.stats,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.showingInactive,
    required this.isBalanceVisible,
    required this.onToggleInactive,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de\nCartera',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: textColor)),
              Row(
                children: [
                  GestureDetector(
                    onTap: onToggleBalance,
                    child: Icon(
                      isBalanceVisible ? Icons.analytics : Icons.analytics_outlined,
                      color: subColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onToggleInactive,
                    child: Icon(
                      showingInactive ? Icons.visibility : Icons.visibility_off_outlined,
                      color: showingInactive ? kAccent : subColor,
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
                  label: 'Clientes',
                  value: stats.totalClientes.toString(),
                  icon: Icons.people_alt_rounded,
                  color: Colors.green),
              const SizedBox(width: 40),
              _StatItem(
                  label: 'Con Deuda',
                  value: stats.clientesConDeuda.toString(),
                  icon: Icons.receipt_long,
                  color: kAccent),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deuda Total',
                      style: TextStyle(color: subColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    isBalanceVisible ? currency.format(stats.deudaTotal) : '******',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: stats.deudaTotal > 0 ? kAccent : Colors.green),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.10),
                    shape: BoxShape.circle),
                child: const Icon(Icons.trending_up, color: kAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
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
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ClienteTile extends ConsumerWidget {
  final Cliente cliente;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ClienteTile({
    required this.cliente,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicial = cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: kAccent.withOpacity(0.15),
          child: Text(inicial,
              style: const TextStyle(
                  color: kAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(cliente.nombre,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 15)),
            ),
            if (cliente.deuda > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CRÉDITO',
                  style: TextStyle(
                      color: kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, size: 13, color: subColor),
                const SizedBox(width: 4),
                Text(
                  cliente.telefono != null && cliente.telefono!.isNotEmpty
                      ? cliente.telefono!
                      : 'Sin teléfono',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
              ],
            ),
            if (cliente.deuda > 0) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Debe: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(cliente.deuda)}',
                  style: const TextStyle(
                      color: kAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subColor),
          onSelected: (v) async {
            if (v == 'ver') onTap();
            if (v == 'editar') onEdit();
            if (v == 'desactivar') {
               final error = await ref.read(clientesProvider.notifier).desactivarCliente(cliente.id);
               if (error != null && context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.orange));
               }
            }
            if (v == 'reactivar') {
              await ref.read(clientesProvider.notifier).reactivarCliente(cliente.id);
            }
            if (v == 'eliminar') {
              if (!context.mounted) return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c2) => AlertDialog(
                  title: const Text('Eliminar Cliente'),
                  content: const Text('¿Estás seguro de eliminar este cliente permanentemente? Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(c2, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(clientesProvider.notifier).eliminarClientePermanentemente(cliente.id);
              }
            }
          },
          itemBuilder: (_) => [
            if (cliente.isActive) ...[
              const PopupMenuItem(
                  value: 'ver',
                  child: const Row(children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 8),
                    Text('Cobrar / Ver')
                  ])),
              const PopupMenuItem(
                  value: 'editar',
                  child: const Row(children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Editar')
                  ])),
              const PopupMenuItem(
                  value: 'desactivar',
                  child: const Row(children: [
                    Icon(Icons.person_off_outlined, size: 20, color: kAccent),
                    SizedBox(width: 8),
                    Text('Desactivar', style: TextStyle(color: kAccent))
                  ])),
            ] else ...[
              const PopupMenuItem(
                  value: 'reactivar',
                  child: const Row(children: [
                    Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Reactivar')
                  ])),
              const PopupMenuItem(
                  value: 'eliminar',
                  child: const Row(children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar Definitivamente', style: TextStyle(color: Colors.red))
                  ])),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyClientes extends StatelessWidget {
  final Color subColor;
  final bool showingInactive;

  const _EmptyClientes({required this.subColor, this.showingInactive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(showingInactive ? Icons.person_off_outlined : Icons.people_outline, size: 64, color: subColor),
            const SizedBox(height: 12),
            Text(showingInactive ? 'No hay clientes desactivados' : 'No hay clientes registrados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: subColor)),
            const SizedBox(height: 8),
            Text(showingInactive ? 'Los clientes que desactives aparecerán aquí.' : 'Toca el botón + para registrar\nun nuevo cliente',
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}