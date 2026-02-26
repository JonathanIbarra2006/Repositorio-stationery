import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../core/utils/pdf_service.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transState = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja y Finanzas'),
        actions: [
          transState.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: 'Exportar Reporte PDF',
              onPressed: () async {
                if (data.transactions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay datos para exportar'))
                  );
                  return;
                }
                await PdfService.generarYCompartirReporteCaja(
                    data.transactions,
                    data.totalIngresos,
                    data.totalGastos,
                    data.balance
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: transState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) => Column(
          children: [
            // --- TARJETA DE RESUMEN (DASHBOARD BÁSICO) ---
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blueAccent.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResumenItem('Ingresos', currency.format(data.totalIngresos), Colors.green),
                  _ResumenItem('Gastos', currency.format(data.totalGastos), Colors.red),
                  _ResumenItem('Balance', currency.format(data.balance), Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- LISTA DE TRANSACCIONES ---
            Expanded(
              child: ListView.builder(
                itemCount: data.transactions.length,
                itemBuilder: (context, index) {
                  final t = data.transactions[index];
                  final isIngreso = t.tipo == TransactionType.ingreso;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIngreso ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIngreso ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(t.descripcion),
                    subtitle: Text(DateFormat('dd/MM/yyyy hh:mm a').format(t.fecha)),
                    trailing: Text(
                      '${isIngreso ? '+' : '-'}${currency.format(t.monto)}',
                      style: TextStyle(
                        color: isIngreso ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // BOTONES FLOTANTES PARA INGRESOS Y GASTOS
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btnGasto',
            backgroundColor: Colors.red[400],
            icon: const Icon(Icons.remove, color: Colors.white),
            label: const Text('Gasto', style: TextStyle(color: Colors.white)),
            onPressed: () => _showTransactionModal(context, ref, TransactionType.gasto),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'btnIngreso',
            backgroundColor: Colors.green[500],
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Ingreso', style: TextStyle(color: Colors.white)),
            onPressed: () => _showTransactionModal(context, ref, TransactionType.ingreso),
          ),
        ],
      ),
    );
  }

  // --- MODAL CON VALIDACIONES (HU01 y HU02) ---
  void _showTransactionModal(BuildContext context, WidgetRef ref, TransactionType tipo) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    String categoria = 'Servicios'; // Por defecto para gastos

    final isGasto = tipo == TransactionType.gasto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isGasto ? 'Registrar Gasto' : 'Registrar Ingreso',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isGasto ? Colors.red : Colors.green)),
              const SizedBox(height: 15),

              // Validación 1: Monto no puede estar vacío ni ser 0
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto (\$)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'El monto es obligatorio';
                  if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Ingrese un valor válido mayor a 0';
                  return null;
                },
                onSaved: (val) => monto = double.parse(val!),
              ),
              const SizedBox(height: 10),

              // Validación 2: Concepto obligatorio
              TextFormField(
                decoration: const InputDecoration(labelText: 'Concepto / Descripción', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Debe ingresar una descripción' : null,
                onSaved: (val) => descripcion = val!,
              ),
              const SizedBox(height: 10),

              // Si es gasto, mostramos el Dropdown de Categorías (Como aprendimos en el paso anterior)
              if (isGasto)
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: ['Servicios', 'Proveedores', 'Insumos', 'Nómina', 'Otros']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => categoria = val!,
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isGasto ? Colors.red : Colors.green),
                  child: const Padding(padding: EdgeInsets.all(12.0), child: Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16))),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      final newTx = AppTransaction(
                        id: const Uuid().v4(),
                        tipo: tipo,
                        monto: monto,
                        fecha: DateTime.now(),
                        descripcion: descripcion.trim(),
                        categoria: isGasto ? categoria : 'Ventas',
                      );

                      final error = await ref.read(transactionsProvider.notifier).addTransaction(newTx);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (error != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Guardado exitoso'), backgroundColor: Colors.green));
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  const _ResumenItem(this.titulo, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        Text(valor, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}