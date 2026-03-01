import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';

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
      ),
      body: Column(
        children: [
          // -------------------------------------------------------
          // 1. TARJETAS DE RESUMEN
          // -------------------------------------------------------
          transactionsAsync.when(
            data: (transactionState) {
              final ingresos = transactionState.totalIngresos;
              final gastos = transactionState.totalGastos;
              final balance = transactionState.balance;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: _InfoCard('Ingresos', ingresos, Colors.green, Icons.arrow_upward)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Gastos', gastos, Colors.red, Icons.arrow_downward)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Balance', balance, Colors.blue, Icons.account_balance_wallet)),
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

          // -------------------------------------------------------
          // 2. LISTA DE MOVIMIENTOS (Solo Lectura)
          // -------------------------------------------------------
          Expanded(
            child: transactionsAsync.when(
              data: (transactionState) {
                final list = transactionState.transactions;
                if (list.isEmpty) return const Center(child: Text('No hay movimientos registrados.'));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final t = list[i];
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
                        subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.fecha)} - ${t.categoria}'),
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

      // -------------------------------------------------------
      // 3. BOTONES FLOTANTES
      // -------------------------------------------------------
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'gasto',
            onPressed: () => _showTransactionModal(context, ref, 'gasto'),
            label: const Text('Registrar Gasto'),
            icon: const Icon(Icons.remove_circle_outline),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'ingreso',
            onPressed: () => _showTransactionModal(context, ref, 'ingreso'),
            label: const Text('Ingreso Extra'),
            icon: const Icon(Icons.add_circle_outline),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // MODAL (Lazy Validation)
  // -------------------------------------------------------
  void _showTransactionModal(BuildContext context, WidgetRef ref, String tipo) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    String categoria = tipo == 'ingreso' ? 'Ventas Extra' : 'Servicios';

    final categorias = tipo == 'ingreso'
        ? ['Ventas Extra', 'Aporte Capital', 'Préstamo', 'Otros']
        : ['Servicios', 'Arriendo', 'Nómina', 'Proveedores', 'Mantenimiento', 'Otros'];

    AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

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
                      autovalidateMode: autovalidateMode,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              tipo == 'ingreso' ? 'Nuevo Ingreso' : 'Nuevo Gasto',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: tipo == 'ingreso' ? Colors.green : Colors.red
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
                            value: categoria,
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
                                  backgroundColor: tipo == 'ingreso' ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white
                              ),
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();

                                  final nuevaTransaccion = AppTransaction(
                                      id: const Uuid().v4(),
                                      tipo: tipo == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto,
                                      monto: monto,
                                      fecha: DateTime.now(),
                                      descripcion: descripcion,
                                      categoria: categoria
                                  );

                                  ref.read(transactionsProvider.notifier).addTransaction(nuevaTransaccion);
                                  Navigator.pop(ctx);
                                } else {
                                  setModalState(() {
                                    autovalidateMode = AutovalidateMode.onUserInteraction;
                                  });
                                }
                              },
                              child: const Text('Guardar', style: TextStyle(fontSize: 18)),
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

// -----------------------------------------------------------
// WIDGET AUXILIAR (Aquí hicimos el cambio de formato)
// -----------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _InfoCard(this.title, this.amount, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    // CAMBIO: Cambiamos 'compactCurrency' (ej: 22 mil) por 'currency' (ej: 22.000)
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withAlpha((255 * 0.1).round()), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          // Aquí aplicamos el formato numérico completo
          Text(currency.format(amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
