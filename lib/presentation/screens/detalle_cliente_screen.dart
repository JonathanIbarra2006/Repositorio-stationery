import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fiado_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/klip_header.dart';
import 'nuevo_cliente_screen.dart';

class DetalleClienteScreen extends ConsumerStatefulWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  @override
  ConsumerState<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends ConsumerState<DetalleClienteScreen> {
  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final historialFuture = ref.read(clientesProvider.notifier).obtenerHistorialCliente(widget.cliente.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : kBg;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final clienteActual = ref.watch(clientesProvider).maybeWhen(
          data: (list) => list.firstWhere((c) => c.id == widget.cliente.id, orElse: () => widget.cliente),
          orElse: () => widget.cliente,
        );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            KlipHeader(
              title: 'Klip',
              badge: 'DETALLE DE COBRO',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: kAccent),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NuevoClienteScreen(clienteAEditar: clienteActual),
                      ),
                    );
                  },
                )
              ],
            ),
            
            Expanded(
              child: FutureBuilder<List<FiadoDetalle>>(
                future: historialFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kAccent));
                  }
                  
                  final deudas = snapshot.data ?? [];
                  final totalDeuda = deudas.fold(0.0, (sum, d) => sum + (d.estado == 'pendiente' ? d.saldoPendiente : 0));

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // --- RESUMEN DEL CLIENTE ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: kAccent.withValues(alpha: 0.1),
                              child: Text(
                                clienteActual.nombre.isNotEmpty ? clienteActual.nombre[0].toUpperCase() : '?',
                                style: const TextStyle(color: kAccent, fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              clienteActual.nombre,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              clienteActual.telefono?.isNotEmpty == true ? clienteActual.telefono! : 'Sin teléfono',
                              style: TextStyle(color: subColor, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (clienteActual.email?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                clienteActual.email!,
                                style: TextStyle(color: subColor, fontSize: 13),
                              ),
                            ],
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text('DEUDA ACTUAL', style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currency.format(totalDeuda),
                                      style: TextStyle(
                                        fontSize: 26, 
                                        fontWeight: FontWeight.w900, 
                                        color: totalDeuda > 0 ? kAccent : Colors.green
                                      ),
                                    ),
                                  ],
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
                            decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Historial de Fiados',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (deudas.isEmpty)
                        _buildEmptyHistory(subColor)
                      else
                        ...deudas.map((d) => _DeudaCard(
                          d: d,
                          currency: currency,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          onAbonar: () => _mostrarModalAbono(d, clienteActual.nombre),
                        )),
                      
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No hay fiados registrados', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // --- MODAL DE ABONOS ---
  void _mostrarModalAbono(FiadoDetalle d, String nombreCliente) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final montoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text('Registrar Abono', style: TextStyle(fontWeight: FontWeight.w900)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo pendiente:', style: TextStyle(fontSize: 14)),
                      Text(currency.format(d.saldoPendiente), style: const TextStyle(fontWeight: FontWeight.w900, color: kAccent, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: montoCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Monto a abonar',
                    prefixIcon: const Icon(Icons.attach_money, color: kAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: kAccent, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final val = double.tryParse(v) ?? 0;
                    if (val <= 0) return 'Mayor a 0';
                    if (val > d.saldoPendiente) return 'No puede ser mayor al saldo';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => montoCtrl.text = d.saldoPendiente.toStringAsFixed(0),
                  child: const Text('Saldar toda la deuda', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final abono = double.parse(montoCtrl.text);
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);

                  await ref.read(clientesProvider.notifier).registrarAbono(
                    fiadoId: d.id,
                    abono: abono,
                    totalDeuda: d.total,
                    loQueYaPago: d.montoPagado,
                    nombreCliente: nombreCliente
                  );
                  ref.invalidate(transactionsProvider);
                  
                  if (!mounted) return;
                  
                  nav.pop();
                  setState(() {});
                  messenger.showSnackBar(SnackBar(content: Text('Abono de ${currency.format(abono)} registrado'), backgroundColor: Colors.green));
                }
              },
              child: const Text('CONFIRMAR PAGO', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}

class _DeudaCard extends StatelessWidget {
  final FiadoDetalle d;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  final VoidCallback onAbonar;

  const _DeudaCard({
    required this.d,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.onAbonar,
  });

  @override
  Widget build(BuildContext context) {
    final esPendiente = d.estado == 'pendiente';
    final fecha = DateTime.parse(d.fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: esPendiente ? kAccent.withValues(alpha: 0.1) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(fecha),
                  style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: esPendiente ? kAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    esPendiente ? 'PENDIENTE' : 'PAGADO',
                    style: TextStyle(
                      color: esPendiente ? kAccent : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              d.productos,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            if (esPendiente) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Abonado: ${currency.format(d.montoPagado)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  Text('Total: ${currency.format(d.total)}', style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: d.montoPagado / d.total,
                  backgroundColor: kAccent.withValues(alpha: 0.1),
                  color: Colors.green,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esPendiente ? 'SALDO PENDIENTE' : 'MONTO TOTAL',
                      style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      esPendiente ? currency.format(d.saldoPendiente) : currency.format(d.total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: esPendiente ? kAccent : Colors.green,
                      ),
                    ),
                  ],
                ),
                if (esPendiente)
                  ElevatedButton(
                    onPressed: onAbonar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('ABONAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}