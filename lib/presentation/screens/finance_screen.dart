import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'venta_contado_screen.dart';
import '../../core/utils/pdf_generator.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Finanzas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // BOTÓN DE EXPORTAR PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'Exportar Reporte PDF',
            onPressed: () async {
              // Obtenemos los datos actuales
              final state = ref.read(transactionsProvider).valueOrNull;
              if (state == null || state.transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
                return;
              }
              // Generamos el reporte
              await PdfGenerator.generateFinanceReport(state.transactions);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. TARJETAS DE RESUMEN
          transactionsAsync.when(
            data: (state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: _InfoCard('Ingresos', state.totalIngresos, Colors.green, Icons.arrow_upward)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Gastos', state.totalGastos, Colors.red, Icons.arrow_downward)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Balance', state.balance, Colors.blue, Icons.account_balance_wallet)),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Padding(padding: const EdgeInsets.all(8.0), child: Text('Error: $e')),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // 2. LISTA DE MOVIMIENTOS
          Expanded(
            child: transactionsAsync.when(
              data: (state) {
                if (state.transactions.isEmpty) return const Center(child: Text('No hay movimientos registrados.'));

                final sortedList = [...state.transactions];
                sortedList.sort((a, b) => b.fecha.compareTo(a.fecha));

                return ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (ctx, i) {
                    final t = sortedList[i];
                    final isIngreso = t.tipo == TransactionType.ingreso;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIngreso ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isIngreso ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(t.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.fecha)} - ${t.categoria ?? ''}'),
                        trailing: Text(
                          '${isIngreso ? '+' : '-'} ${currency.format(t.monto)}',
                          style: TextStyle(
                              color: isIngreso ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),

      // 3. BOTONES DE ACCIÓN
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'gasto',
            onPressed: () => _showTransactionModal(context, ref, 'gasto'),
            label: const Text('Gasto'),
            icon: const Icon(Icons.remove_circle_outline),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 10),

          FloatingActionButton.extended(
            heroTag: 'ingreso',
            onPressed: () => _showTransactionModal(context, ref, 'ingreso'),
            label: const Text('Ingreso Extra'),
            icon: const Icon(Icons.attach_money),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 15),

          FloatingActionButton.extended(
            heroTag: 'venta',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VentaDeContadoScreen())
              );
            },
            label: const Text('NUEVA VENTA', style: TextStyle(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.point_of_sale, size: 28),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 6,
          ),
        ],
      ),
    );
  }

  void _showTransactionModal(BuildContext context, WidgetRef ref, String tipoString) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    String categoria = tipoString == 'ingreso' ? 'Ventas Extra' : 'Servicios';

    final categorias = tipoString == 'ingreso'
        ? ['Ventas Extra', 'Aporte Capital', 'Préstamo', 'Otros']
        : ['Servicios', 'Arriendo', 'Nómina', 'Proveedores', 'Mantenimiento', 'Otros'];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      left: 16, right: 16, top: 16
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              tipoString == 'ingreso' ? 'Nuevo Ingreso' : 'Nuevo Gasto',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: tipoString == 'ingreso' ? Colors.green : Colors.red
                              )
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Monto *', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              if (double.tryParse(val) == 0) return 'Mayor a 0';
                              return null;
                            },
                            onSaved: (val) => monto = double.parse(val!),
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Descripción *', prefixIcon: Icon(Icons.description), border: OutlineInputBorder()),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
                            onSaved: (val) => descripcion = val!,
                          ),
                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(
                            initialValue: categoria,
                            decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                            items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => categoria = val!,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: tipoString == 'ingreso' ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white
                              ),
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();

                                  final nuevaTransaccion = AppTransaction(
                                      id: const Uuid().v4(),
                                      tipo: tipoString == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto,
                                      monto: monto,
                                      fecha: DateTime.now(),
                                      descripcion: descripcion,
                                      categoria: categoria
                                  );

                                  ref.read(transactionsProvider.notifier).addTransaction(nuevaTransaccion);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Guardar Movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _InfoCard(this.title, this.amount, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50))
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              currency.format(amount),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
