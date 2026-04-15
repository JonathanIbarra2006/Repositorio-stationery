import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/proveedor.dart';
import '../providers/proveedor_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart' show AppHeader;

class ProveedoresScreen extends ConsumerWidget {
  const ProveedoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proveedoresProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : kBg;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            const AppHeader(moduleBadge: 'PROVEEDORES'),

            Expanded(
              child: state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ResumenProvCard(
                      total: list.length,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Listado de Proveedores',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty)
                      _EmptyProveedores(subColor: subColor)
                    else
                      ...list.map((p) => _ProveedorTile(
                            proveedor: p,
                            cardColor: cardColor,
                            textColor: textColor,
                            subColor: subColor,
                            onEdit: () => _modal(context, ref,
                                prov: p, isDark: isDark),
                            onDelete: () =>
                                _confirmDelete(context, ref, p),
                          )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        onPressed: () => _modal(context, ref, isDark: isDark),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // ── Modal Nuevo / Editar proveedor ────────────────────────────────────
  void _modal(BuildContext context, WidgetRef ref,
      {Proveedor? prov, required bool isDark}) {
    final formKey = GlobalKey<FormState>();
    final esEdicion = prov != null;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor =
        isDark ? Colors.grey.shade600 : Colors.black;

    String empresa = prov?.empresa ?? '';
    String nombre = prov?.nombre ?? '';
    String telefono = '';
    String correo = '';

    if (esEdicion) {
      final partes = prov.contacto.split(' | ');
      telefono = partes[0];
      if (partes.length > 1) correo = partes[1];
    }

    InputDecoration dec(String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: textColor, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: textColor),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent, width: 2.5)),
        );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: empresa,
                  style: TextStyle(color: textColor),
                  decoration:
                      dec('Nombre de la Empresa *', Icons.business),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                  onSaved: (v) => empresa = v!.trim(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: nombre,
                  style: TextStyle(color: textColor),
                  decoration:
                      dec('Nombre del Encargado *', Icons.person),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                  onSaved: (v) => nombre = v!.trim(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: telefono,
                  style: TextStyle(color: textColor),
                  decoration: dec('Teléfono *', Icons.phone),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.trim().isEmpty || v.length < 7
                          ? 'Mínimo 7 dígitos'
                          : null,
                  onSaved: (v) => telefono = v!.trim(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: correo,
                  style: TextStyle(color: textColor),
                  decoration: dec('Correo (Opcional)', Icons.email)
                      .copyWith(
                    hintText: 'ejemplo@correo.com',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final re = RegExp(
                        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                    return re.hasMatch(val.trim())
                        ? null
                        : 'Correo no válido';
                  },
                  onSaved: (v) => correo = v?.trim() ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                String contacto = telefono;
                if (correo.isNotEmpty) contacto += ' | $correo';
                final nuevo = Proveedor(
                    id: esEdicion ? prov.id : const Uuid().v4(),
                    nombre: nombre,
                    contacto: contacto,
                    empresa: empresa);
                esEdicion
                    ? ref
                        .read(proveedoresProvider.notifier)
                        .updateProveedor(nuevo)
                    : ref
                        .read(proveedoresProvider.notifier)
                        .addProveedor(nuevo);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Proveedor p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: Text('¿Eliminar a ${p.empresa}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref
                  .read(proveedoresProvider.notifier)
                  .deleteProveedor(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Card resumen ──────────────────────────────────────────────────────────────
class _ResumenProvCard extends StatelessWidget {
  final int total;
  final Color cardColor, textColor, subColor;

  const _ResumenProvCard({
    required this.total,
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
              Text('Resumen Proveedores',
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
              _ProvStat(
                  label: 'Total',
                  value: total.toString(),
                  icon: Icons.local_shipping_rounded,
                  color: Colors.green),
              const SizedBox(width: 40),
              _ProvStat(
                  label: 'Con Ruta',
                  value: '0',
                  icon: Icons.alt_route,
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
                  Text('Estadísticas',
                      style: TextStyle(color: subColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(total.toString(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kAccent)),
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

class _ProvStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _ProvStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
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
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Tile de proveedor ─────────────────────────────────────────────────────────
class _ProveedorTile extends StatelessWidget {
  final Proveedor proveedor;
  final Color cardColor, textColor, subColor;
  final VoidCallback onEdit, onDelete;

  const _ProveedorTile({
    required this.proveedor,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = proveedor.empresa.isNotEmpty
        ? proveedor.empresa[0].toUpperCase()
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
        title: Text(proveedor.empresa,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 15)),
        subtitle: Text(
          '${proveedor.nombre} · ${proveedor.contacto.split(' | ')[0]}',
          style: TextStyle(color: subColor, fontSize: 13),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: subColor),
          onSelected: (v) {
            if (v == 'editar') onEdit();
            if (v == 'eliminar') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Editar')
                ])),
            PopupMenuItem(
                value: 'eliminar',
                child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar',
                      style: TextStyle(color: Colors.red))
                ])),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyProveedores extends StatelessWidget {
  final Color subColor;
  const _EmptyProveedores({required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 72, color: subColor),
            const SizedBox(height: 16),
            Text('No hay proveedores',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: subColor)),
            const SizedBox(height: 8),
            Text(
                'Registra proveedores para asociarlos a\nproductos del inventario.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}