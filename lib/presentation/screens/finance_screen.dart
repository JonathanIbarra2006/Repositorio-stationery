import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../core/utils/pdf_generator.dart';
import 'venta_contado_screen.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: const Text('Finanzas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'Exportar Reporte PDF',
            onPressed: () async {
              final transacciones = ref.read(transactionsProvider).valueOrNull?.transactions ?? [];
              if (transacciones.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
                return;
              }
              await PdfGenerator.generateFinanceReport(transacciones);
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
              final ingresos = state.totalIngresos;
              final gastos = state.totalGastos;
              final balance = state.balance;

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

          // 2. LISTA DE MOVIMIENTOS
          Expanded(
            child: transactionsAsync.when(
              data: (state) {
                if (state.transactions.isEmpty) return const Center(child: Text('No hay movimientos registrados.', style: TextStyle(color: Colors.grey)));

                final sortedList = [...state.transactions];
                sortedList.sort((a, b) => b.fecha.compareTo(a.fecha));

                return ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (ctx, i) {
                    final t = sortedList[i];
                    final isIngreso = t.tipo == TransactionType.ingreso;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  // -------------------------------------------------------
  // MODAL OPTIMIZADO CON ESTILO ALTO CONTRASTE
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

    // ESTILO ALTO CONTRASTE (NEGRO Y GRUESO)
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // Transparente para esquinas redondeadas
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25))
                  ),
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      left: 20, right: 20, top: 20
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      autovalidateMode: autovalidateMode,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                          const SizedBox(height: 20),

                          Text(
                              tipo == 'ingreso' ? 'Nuevo Ingreso' : 'Nuevo Gasto',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: tipo == 'ingreso' ? Colors.green : Colors.red
                              )
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            decoration: inputDecoration('Monto *', Icons.attach_money),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              if (double.tryParse(val) == 0) return 'Mayor a 0';
                              return null;
                            },
                            onSaved: (val) => monto = double.parse(val!),
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            decoration: inputDecoration('Descripción *', Icons.description),
                            textCapitalization: TextCapitalization.sentences,
                            validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
                            onSaved: (val) => descripcion = val!,
                          ),
                          const SizedBox(height: 15),

                          DropdownButtonFormField<String>(
                            value: categoria,
                            decoration: inputDecoration('Categoría', Icons.category),
                            items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => categoria = val!,
                          ),
                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: tipo == 'ingreso' ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
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
                              child: const Text('Guardar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(currency.format(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
