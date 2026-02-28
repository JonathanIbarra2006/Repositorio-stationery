import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/fiado_provider.dart';
import '../providers/transaction_provider.dart';

class DetalleClienteScreen extends ConsumerStatefulWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  @override
  ConsumerState<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends ConsumerState<DetalleClienteScreen> {
  late String _nombreActual;
  late String _telefonoActual;

  @override
  void initState() {
    super.initState();
    _nombreActual = widget.cliente.nombre;
    _telefonoActual = widget.cliente.telefono ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final historialFuture = ref.read(clientesProvider.notifier).obtenerHistorialCliente(widget.cliente.id);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text('Estado de Cuenta', style: TextStyle(fontSize: 14)),
            Text(_nombreActual, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _mostrarDialogoEditar)
        ],
      ),
      body: FutureBuilder<List<FiadoDetalle>>(
        future: historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Cliente sin historial.'));

          final deudas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deudas.length,
            itemBuilder: (ctx, i) {
              final d = deudas[i];
              final esPendiente = d.estado == 'pendiente';
              final fecha = DateTime.parse(d.fecha);

              return Card(
                elevation: esPendiente ? 3 : 0,
                color: esPendiente ? Colors.white : Colors.grey[200],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: esPendiente ? Colors.orange.shade200 : Colors.transparent, width: 1.5),
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado Fecha y Estado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy - hh:mm a').format(fecha), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Chip(
                            label: Text(esPendiente ? 'PENDIENTE' : 'PAGADO', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: esPendiente ? Colors.orange : Colors.green,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )
                        ],
                      ),
                      const Divider(),

                      // Productos
                      Text(d.productos, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),

                      // BARRA DE PROGRESO DE PAGO
                      if (esPendiente)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: d.montoPagado / d.total,
                              backgroundColor: Colors.orange.shade100,
                              color: Colors.green,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Abonado: ${currency.format(d.montoPagado)}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                Text('Total: ${currency.format(d.total)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 10),

                      // AREA DE TOTALES Y BOTÓN
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (esPendiente) const Text('Saldo Restante:', style: TextStyle(fontSize: 12, color: Colors.red)),
                              Text(
                                  esPendiente ? currency.format(d.saldoPendiente) : currency.format(d.total),
                                  style: TextStyle(fontSize: 20, color: esPendiente ? Colors.red : Colors.green[700], fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),

                          if (esPendiente)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                              icon: const Icon(Icons.attach_money, size: 18),
                              label: const Text('ABONAR'),
                              onPressed: () => _mostrarModalAbono(d),
                            )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- MODAL DE ABONOS ---
  void _mostrarModalAbono(FiadoDetalle d) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final montoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Registrar Abono'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Saldo actual: ${currency.format(d.saldoPendiente)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 20),

                // Opción 1: Saldar todo
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      montoCtrl.text = d.saldoPendiente.toStringAsFixed(0);
                    },
                    child: const Text('Saldar Toda la Deuda'),
                  ),
                ),
                const SizedBox(height: 10),

                // Opción 2: Campo manual
                TextFormField(
                  controller: montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto a abonar hoy', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final abono = double.parse(montoCtrl.text);

                  await ref.read(clientesProvider.notifier).registrarAbono(
                      fiadoId: d.id,
                      abono: abono,
                      totalDeuda: d.total,
                      loQueYaPago: d.montoPagado,
                      nombreCliente: _nombreActual
                  );

                  ref.invalidate(transactionsProvider);
                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abono de ${currency.format(abono)} registrado'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('CONFIRMAR PAGO'),
            )
          ],
        );
      },
    );
  }

  void _mostrarDialogoEditar() {
    final nombreCtrl = TextEditingController(text: _nombreActual);
    final telCtrl = TextEditingController(text: _telefonoActual);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v!.isEmpty?'Requerido':null),
              const SizedBox(height: 10),
              TextFormField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone)
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (formKey.currentState!.validate()) {
              await ref.read(clientesProvider.notifier).editarCliente(widget.cliente.id, nombreCtrl.text.trim(), telCtrl.text.trim());
              setState(() { _nombreActual = nombreCtrl.text.trim(); _telefonoActual = telCtrl.text.trim(); });
              if (mounted) Navigator.pop(ctx);
            }
          }, child: const Text('Guardar'))
        ],
      ),
    );
  }
}