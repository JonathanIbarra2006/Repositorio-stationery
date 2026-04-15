import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/database_helper.dart';
import '../providers/fiado_provider.dart';
import '../theme/app_colors.dart';
import 'detalle_cliente_screen.dart';
import 'home_screen.dart' show AppHeader;

class FiadosScreen extends ConsumerWidget {
  const FiadosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesProvider);
    final statsAsync = ref.watch(carteraStatsProvider);
    final currency =
        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : kBg;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            const AppHeader(moduleBadge: 'GESTIÓN DE CLIENTES'),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Card de cartera ─────────────────────────────────
                  statsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stats) => _CarteraCard(
                      stats: stats,
                      currency: currency,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Título sección ────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Listado de Clientes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Lista ─────────────────────────────────────────
                  clientesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: kAccent)),
                    error: (e, _) =>
                        Center(child: Text('Error: $e')),
                    data: (clientes) {
                      if (clientes.isEmpty) {
                        return _EmptyClientes(subColor: subColor);
                      }
                      return Column(
                        children: clientes
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
                                  onEdit: () => _showEditDialog(
                                      context, ref, c),
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
        onPressed: () => _showNuevoClienteSheet(context, ref),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // ── Sheet: Nuevo cliente ────────────────────────────────────────────────
  void _showNuevoClienteSheet(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 16),
              Text('Nuevo Cliente',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreCtrl,
                style: TextStyle(color: textColor),
                decoration:
                    _inputDeco('Nombre completo *', Icons.person, textColor),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDeco('Teléfono *', Icons.phone, textColor),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.length < 7 ? 'Mínimo 7 dígitos' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final db =
                        await DatabaseHelper.instance.database;
                    await db.insert('clientes', {
                      'id': const Uuid().v4(),
                      'nombre': nombreCtrl.text.trim(),
                      'telefono': telefonoCtrl.text.trim(),
                    });
                    ref.invalidate(clientesProvider);
                    ref.invalidate(carteraStatsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Registrar Cliente',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog: Editar cliente ────────────────────────────────────────────
  void _showEditDialog(BuildContext context, WidgetRef ref, Cliente c) {
    final nombreCtrl = TextEditingController(text: c.nombre);
    final telefonoCtrl = TextEditingController(text: c.telefono ?? '');
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar Cliente',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDeco('Nombre', Icons.person, textColor),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDeco('Teléfono', Icons.phone, textColor),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(clientesProvider.notifier).editarCliente(
                    c.id,
                    nombreCtrl.text.trim(),
                    telefonoCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(
      String label, IconData icon, Color textColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor),
      prefixIcon: Icon(icon, color: textColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Card Gestión de Cartera ───────────────────────────────────────────────────
class _CarteraCard extends StatelessWidget {
  final CarteraStats stats;
  final NumberFormat currency;
  final Color cardColor;
  final Color textColor;
  final Color subColor;

  const _CarteraCard({
    required this.stats,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
              Text('Gestión de Cartera',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
              Icon(Icons.remove_red_eye_outlined, color: subColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CarteraStat(
                  label: 'Clientes',
                  value: stats.totalClientes.toString(),
                  icon: Icons.people_alt_rounded,
                  color: Colors.green),
              const SizedBox(width: 40),
              _CarteraStat(
                  label: 'Con Deuda',
                  value: stats.clientesConDeuda.toString(),
                  icon: Icons.receipt_long,
                  color: kAccent),
            ],
          ),
          const Divider(height: 28),
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
                    currency.format(stats.deudaTotal),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: stats.deudaTotal > 0
                            ? kAccent
                            : Colors.green),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.trending_up, color: kAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarteraStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CarteraStat(
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
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Tile de cliente ───────────────────────────────────────────────────────────
class _ClienteTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final inicial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';

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
      child: ListTile(
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
        title: Text(cliente.nombre,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 15)),
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
          onSelected: (v) {
            if (v == 'ver') onTap();
            if (v == 'editar') onEdit();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'ver',
                child: Row(children: [
                  Icon(Icons.visibility_outlined),
                  SizedBox(width: 8),
                  Text('Ver detalle')
                ])),
            PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Editar')
                ])),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyClientes extends StatelessWidget {
  final Color subColor;

  const _EmptyClientes({required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: subColor),
            const SizedBox(height: 12),
            Text('No hay clientes registrados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: subColor)),
            const SizedBox(height: 8),
            Text('Toca el botón + para registrar\nun nuevo cliente',
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}