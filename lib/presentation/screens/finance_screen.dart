import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../core/utils/pdf_service.dart';
import 'venta_contado_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  DateTimeRange? _rangoFechas; // Guarda las fechas seleccionadas

  @override
  Widget build(BuildContext context) {
    final transState = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja y Finanzas'),
        actions: [
          // NUEVO BOTÓN: FILTRO POR FECHAS (CALENDARIO)
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.blueAccent),
            tooltip: 'Filtrar por fecha',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024), // Desde cuando se usa la app
                lastDate: DateTime.now(),
                initialDateRange: _rangoFechas,
                helpText: 'Selecciona las fechas a consultar',
              );

              if (picked != null) {
                setState(() => _rangoFechas = picked);
                ref.read(transactionsProvider.notifier).loadTransactions(startDate: picked.start, endDate: picked.end);
              }
            },
          ),
          // BOTÓN DE PDF (Existente)
          transState.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: 'Exportar Reporte PDF',
              onPressed: () async {
                if (data.transactions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
                  return;
                }
                await PdfService.generarYCompartirReporteCaja(data.transactions, data.totalIngresos, data.totalGastos, data.balance);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: Column(
        children: [
          // INDICADOR DE FILTRO ACTIVO
          if (_rangoFechas != null)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtrando: ${DateFormat('dd/MM/yy').format(_rangoFechas!.start)} al ${DateFormat('dd/MM/yy').format(_rangoFechas!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    onPressed: () {
                      setState(() => _rangoFechas = null);
                      ref.read(transactionsProvider.notifier).loadTransactions(); // Recarga todo sin filtro
                    },
                  )
                ],
              ),
            ),

          // DASHBOARD Y LISTADO (Existente)
          Expanded(
            child: transState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                return Column(
                  children: [
                    // Dashboard de Totales
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10, spreadRadius: 2)]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResumen('Ingresos', data.totalIngresos, Colors.green, currency),
                          _buildResumen('Gastos', data.totalGastos, Colors.red, currency),
                          _buildResumen('Balance', data.balance, Colors.blue, currency),
                        ],
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 10),

                    // Lista de transacciones
                    Expanded(
                      child: data.transactions.isEmpty
                          ? const Center(child: Text('No hay movimientos en estas fechas.'))
                          : ListView.builder(
                        itemCount: data.transactions.length,
                        itemBuilder: (ctx, i) {
                          final t = data.transactions[i];
                          final esIngreso = t.tipo == TransactionType.ingreso;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: esIngreso ? Colors.green[100] : Colors.red[100], child: Icon(esIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: esIngreso ? Colors.green : Colors.red)),
                            title: Text(t.descripcion),
                            subtitle: Text('${DateFormat('dd MMM yyyy - hh:mm a').format(t.fecha)}\nCategoría: ${t.categoria}'),
                            isThreeLine: true,
                            trailing: Text(currency.format(t.monto), style: TextStyle(color: esIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // BOTONES INFERIORES (Existentes)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btnVender',
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.point_of_sale, color: Colors.white),
            label: const Text('Vender (Contado)', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VentaContadoScreen())),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'btnGasto',
            backgroundColor: Colors.red[400],
            icon: const Icon(Icons.remove, color: Colors.white),
            label: const Text('Registrar Gasto', style: TextStyle(color: Colors.white)),
            onPressed: () => _showTransactionModal(context, ref, TransactionType.gasto),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'btnIngreso',
            backgroundColor: Colors.green[500],
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Ingreso Extra', style: TextStyle(color: Colors.white)),
            onPressed: () => _showTransactionModal(context, ref, TransactionType.ingreso),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(String titulo, double valor, Color color, NumberFormat currency) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(currency.format(valor), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showTransactionModal(BuildContext context, WidgetRef ref, TransactionType tipo) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    String categoria = '';
    final esIngreso = tipo == TransactionType.ingreso;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(esIngreso ? 'Nuevo Ingreso Extra' : 'Registrar Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: esIngreso ? Colors.green : Colors.red)),
              const SizedBox(height: 15),
              TextFormField(
                decoration: InputDecoration(labelText: 'Monto (\$)', border: const OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money, color: esIngreso ? Colors.green : Colors.red)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onSaved: (val) => monto = double.parse(val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: (esIngreso ? ['Otros Ingresos'] : ['Servicios', 'Proveedores', 'Insumos', 'Nómina', 'Otros'])
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onChanged: (val) => categoria = val!,
                onSaved: (val) => categoria = val!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción / Concepto', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                onSaved: (val) => descripcion = val!,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: esIngreso ? Colors.green : Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final transaccion = AppTransaction(id: const Uuid().v4(), tipo: tipo, monto: monto, fecha: DateTime.now(), descripcion: descripcion, categoria: categoria);
                      await ref.read(transactionRepoProvider).addTransaction(transaccion);
                      if (ctx.mounted) {
                        ref.invalidate(transactionsProvider);
                        Navigator.pop(ctx);
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(fontSize: 16)),
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