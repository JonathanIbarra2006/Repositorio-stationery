import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';
import 'nuevo_cliente_screen.dart';
import 'cuenta_cliente_screen.dart';
import '../widgets/klip_header.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  bool _showingInactive = false;

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
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
                  // Tarjeta de resumen de clientes
                  clientesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    // ignore: avoid_types_on_closure_parameters
                    error: (Object e, StackTrace s) => const SizedBox.shrink(),
                    data: (clientes) {
                      final activos = clientes.where((c) => c.isActive).length;
                      final inactivos = clientes.where((c) => !c.isActive).length;
                      return _ResumenCard(
                        totalActivos: activos,
                        totalInactivos: inactivos,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        showingInactive: _showingInactive,
                        onToggleInactive: () =>
                            setState(() => _showingInactive = !_showingInactive),
                      );
                    },
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
                        _showingInactive
                            ? 'Clientes Desactivados'
                            : 'Listado de Clientes',
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
                      final filtered = clientes
                          .where((c) => c.isActive == !_showingInactive)
                          .toList();
                      if (filtered.isEmpty) {
                        return _EmptyClientes(
                          subColor: subColor,
                          showingInactive: _showingInactive,
                        );
                      }
                      return Column(
                        children: filtered
                            .map((c) => _ClienteTile(
                                  cliente: c,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subColor: subColor,
                                  onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NuevoClienteScreen(
                                              clienteAEditar: c))),
                                  onVerCuenta: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              CuentaClienteScreen(cliente: c))),
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
        heroTag: null,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NuevoClienteScreen())),
        backgroundColor: kAccent,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.person_add_alt_1_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA DE RESUMEN
// ─────────────────────────────────────────────────────────────
class _ResumenCard extends StatelessWidget {
  final int totalActivos;
  final int totalInactivos;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool showingInactive;
  final VoidCallback onToggleInactive;

  const _ResumenCard({
    required this.totalActivos,
    required this.totalInactivos,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.showingInactive,
    required this.onToggleInactive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.4
                    : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Directorio de\nClientes',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: textColor),
              ),
              GestureDetector(
                onTap: onToggleInactive,
                child: Icon(
                  showingInactive
                      ? Icons.visibility
                      : Icons.visibility_off_outlined,
                  color: showingInactive ? kAccent : subColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatItem(
                label: 'Activos',
                value: totalActivos.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.green,
              ),
              const SizedBox(width: 40),
              _StatItem(
                label: 'Inactivos',
                value: totalInactivos.toString(),
                icon: Icons.person_off_outlined,
                color: subColor,
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

  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

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
                  color: color.withValues(alpha: 0.12),
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
        Text(value,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TILE DE CLIENTE — con badge de deuda y botón "Ver Cuenta"
// ─────────────────────────────────────────────────────────────
class _ClienteTile extends ConsumerWidget {
  final Cliente cliente;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onEdit;
  final VoidCallback onVerCuenta;

  const _ClienteTile({
    required this.cliente,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onEdit,
    required this.onVerCuenta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicial =
        cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: kAccent.withValues(alpha: 0.15),
              child: Text(inicial,
                  style: const TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            title: Text(
              cliente.nombre,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 15),
            ),
            subtitle: Row(
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
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: subColor),
              onSelected: (v) async {
                if (v == 'editar') onEdit();
                if (v == 'ver_cuenta') onVerCuenta();
                if (v == 'desactivar') {
                  final error = await ref
                      .read(clientesProvider.notifier)
                      .desactivarCliente(cliente.id);
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.orange));
                  }
                }
                if (v == 'reactivar') {
                  await ref
                      .read(clientesProvider.notifier)
                      .reactivarCliente(cliente.id);
                }
                if (v == 'eliminar') {
                  if (!context.mounted) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c2) => AlertDialog(
                      title: const Text('Eliminar Cliente'),
                      content: const Text(
                          '¿Estás seguro de eliminar este cliente permanentemente? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c2, false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.pop(c2, true),
                            child: const Text('Eliminar',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(clientesProvider.notifier)
                        .eliminarClientePermanentemente(cliente.id);
                  }
                }
              },
              itemBuilder: (_) => [
                if (cliente.isActive) ...[
                  const PopupMenuItem(
                      value: 'ver_cuenta',
                      child: Row(children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 20, color: kWarning),
                        SizedBox(width: 8),
                        Text('Ver Cuenta / Cobrar',
                            style: TextStyle(color: kWarning))
                      ])),
                  const PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Editar')
                      ])),
                  const PopupMenuItem(
                      value: 'desactivar',
                      child: Row(children: [
                        Icon(Icons.person_off_outlined,
                            size: 20, color: kAccent),
                        SizedBox(width: 8),
                        Text('Desactivar',
                            style: TextStyle(color: kAccent))
                      ])),
                ] else ...[
                  const PopupMenuItem(
                      value: 'reactivar',
                      child: Row(children: [
                        Icon(Icons.check_circle_outline,
                            size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Reactivar')
                      ])),
                  const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(children: [
                        Icon(Icons.delete_forever,
                            size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar Definitivamente',
                            style: TextStyle(color: Colors.red))
                      ])),
                ],
              ],
            ),
          ),

          // ── Botón "Ver Cuenta / Cobrar" siempre visible ────────
          if (cliente.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kWarning,
                    side: BorderSide(
                        color: kWarning.withValues(alpha: 0.4), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 17),
                  label: const Text('Ver Cuenta / Cobrar',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: onVerCuenta,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADO VACÍO
// ─────────────────────────────────────────────────────────────
class _EmptyClientes extends StatelessWidget {
  final Color subColor;
  final bool showingInactive;

  const _EmptyClientes(
      {required this.subColor, this.showingInactive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
                showingInactive
                    ? Icons.person_off_outlined
                    : Icons.people_outline,
                size: 64,
                color: subColor),
            const SizedBox(height: 12),
            Text(
                showingInactive
                    ? 'No hay clientes desactivados'
                    : 'No hay clientes registrados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: subColor)),
            const SizedBox(height: 8),
            Text(
                showingInactive
                    ? 'Los clientes que desactives aparecerán aquí.'
                    : 'Toca el botón + para registrar\nun nuevo cliente',
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
