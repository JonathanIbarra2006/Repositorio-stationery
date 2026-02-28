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
  DateTimeRange? _rangoFechas;

  @override
  Widget build(BuildContext context) {
    final transState = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Caja y Finanzas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.blueAccent),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: _rangoFechas,
              );
              if (picked != null) {
                setState(() => _rangoFechas = picked);
                ref.read(transactionsProvider.notifier).loadTransactions(startDate: picked.start, endDate: picked.end);
              }
            },
          ),
          transState.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () async {
                if (data.transactions.isNotEmpty) {
                  await PdfService.generarYCompartirReporteCaja(data.transactions, data.totalIngresos, data.totalGastos, data.balance);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay movimientos para exportar')));
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: Column(
        children: [
          if (_rangoFechas != null)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtro: ${DateFormat('dd/MM').format(_rangoFechas!.start)} - ${DateFormat('dd/MM').format(_rangoFechas!.end)}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  TextButton(child: const Text('Limpiar'), onPressed: () { setState(() => _rangoFechas = null); ref.read(transactionsProvider.notifier).loadTransactions(); })
                ],
              ),
            ),
          Expanded(
            child: transState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResumen('Ingresos', data.totalIngresos, Colors.green, currency),
                          _buildResumen('Gastos', data.totalGastos, Colors.red, currency),
                          _buildResumen('Balance', data.balance, Colors.blue, currency),
                        ],
                      ),
                    ),
                    Expanded(
                      child: data.transactions.isEmpty
                          ? const Center(child: Text('Sin movimientos'))
                          : ListView.builder(
                        itemCount: data.transactions.length,
                        itemBuilder: (ctx, i) {
                          final t = data.transactions[i];
                          final esIngreso = t.tipo == TransactionType.ingreso;
                          return ListTile(
                            leading: Icon(esIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: esIngreso ? Colors.green : Colors.red),
                            title: Text(t.descripcion),
                            subtitle: Text(DateFormat('dd MMM - hh:mm a').format(t.fecha)),
                            trailing: Text(currency.format(t.monto), style: TextStyle(color: esIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(heroTag: 'vender', backgroundColor: Colors.blue, child: const Icon(Icons.point_of_sale, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentaContadoScreen()))),
          const SizedBox(height: 10),
          FloatingActionButton.small(heroTag: 'gasto', backgroundColor: Colors.red, child: const Icon(Icons.remove, color: Colors.white), onPressed: () => _showModal(context, ref, TransactionType.gasto)),
          const SizedBox(height: 10),
          FloatingActionButton.small(heroTag: 'ingreso', backgroundColor: Colors.green, child: const Icon(Icons.add, color: Colors.white), onPressed: () => _showModal(context, ref, TransactionType.ingreso)),
        ],
      ),
    );
  }

  Widget _buildResumen(String t, double v, Color c, NumberFormat f) => Column(children: [Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(f.format(v), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c))]);

  void _showModal(BuildContext context, WidgetRef ref, TransactionType tipo) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String desc = '';
    String cat = '';
    final esIngreso = tipo == TransactionType.ingreso;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
                child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(esIngreso ? 'Nuevo Ingreso' : 'Registrar Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: esIngreso ? Colors.green : Colors.red)),
                          const SizedBox(height: 15),

                          // VALIDACIÓN DE MONTO
                          TextFormField(
                              decoration: const InputDecoration(labelText: 'Monto *', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (double.tryParse(v) == 0) return '> 0';
                                return null;
                              },
                              onSaved: (v) => monto = double.parse(v!)
                          ),
                          const SizedBox(height: 10),

                          // VALIDACIÓN DE CATEGORÍA
                          DropdownButtonFormField<String>(
                            items: (esIngreso ? ['Ventas', 'Servicios', 'Otros'] : ['Servicios', 'Proveedores', 'Insumos', 'Nómina', 'Otros'])
                                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => cat = v.toString(),
                            decoration: const InputDecoration(labelText: 'Categoría *', border: OutlineInputBorder()),
                            validator: (v) => v == null ? 'Seleccione categoría' : null,
                          ),
                          const SizedBox(height: 10),

                          // VALIDACIÓN DE DESCRIPCIÓN
                          TextFormField(
                              decoration: const InputDecoration(labelText: 'Descripción / Concepto *', border: OutlineInputBorder()),
                              textCapitalization: TextCapitalization.sentences,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                              onSaved: (v) => desc = v!
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: esIngreso ? Colors.green : Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                if(formKey.currentState!.validate()){
                                  formKey.currentState!.save();
                                  ref.read(transactionRepoProvider).addTransaction(AppTransaction(id: const Uuid().v4(), tipo: tipo, monto: monto, fecha: DateTime.now(), descripcion: desc, categoria: cat));
                                  ref.invalidate(transactionsProvider);
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Guardar')
                          ),
                          const SizedBox(height: 20)
                        ]
                    )
                )
            )
        )
    );
  }
}