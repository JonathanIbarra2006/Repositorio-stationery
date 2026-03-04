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

    // MODO OSCURO
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text('Finanzas', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'Exportar Reporte PDF',
            onPressed: () async {
              final state = ref.read(transactionsProvider).valueOrNull;
              if (state != null && state.transactions.isNotEmpty) {
                await PdfGenerator.generateFinanceReport(state.transactions);
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          transactionsAsync.when(
            data: (state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: _InfoCard('Ingresos', state.totalIngresos, Colors.green, Icons.arrow_upward, cardColor, textColor)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Gastos', state.totalGastos, Colors.red, Icons.arrow_downward, cardColor, textColor)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCard('Balance', state.balance, Colors.blue, Icons.account_balance_wallet, cardColor, textColor)),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),

          Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ),
          ),

          Expanded(
            child: transactionsAsync.when(
              data: (state) {
                if (state.transactions.isEmpty) return Center(child: Text('No hay movimientos.', style: TextStyle(color: subTextColor)));
                final sortedList = [...state.transactions];
                sortedList.sort((a, b) => b.fecha.compareTo(a.fecha));

                return ListView.builder(
                  itemCount: sortedList.length,
                  itemBuilder: (ctx, i) {
                    final t = sortedList[i];
                    final isIngreso = t.tipo == TransactionType.ingreso;
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIngreso ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100) : (isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade100),
                          child: Icon(isIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: isIngreso ? Colors.green : Colors.red),
                        ),
                        title: Text(t.descripcion, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.fecha)} - ${t.categoria}', style: TextStyle(color: subTextColor)),
                        trailing: Text(
                          '${isIngreso ? '+' : '-'} ${currency.format(t.monto)}',
                          style: TextStyle(color: isIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
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

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(heroTag: 'gasto', onPressed: () => _showTransactionModal(context, ref, 'gasto', isDark), label: const Text('Gasto'), icon: const Icon(Icons.remove_circle_outline), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          const SizedBox(height: 10),
          FloatingActionButton.extended(heroTag: 'ingreso', onPressed: () => _showTransactionModal(context, ref, 'ingreso', isDark), label: const Text('Ingreso Extra'), icon: const Icon(Icons.attach_money), backgroundColor: Colors.blue, foregroundColor: Colors.white),
          const SizedBox(height: 15),
          FloatingActionButton.extended(heroTag: 'venta', onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const VentaDeContadoScreen())); }, label: const Text('NUEVA VENTA', style: TextStyle(fontWeight: FontWeight.bold)), icon: const Icon(Icons.point_of_sale, size: 28), backgroundColor: Colors.teal, foregroundColor: Colors.white, elevation: 6),
        ],
      ),
    );
  }

  void _showTransactionModal(BuildContext context, WidgetRef ref, String tipoString, bool isDark) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    final TransactionType tipo = tipoString == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto;
    String categoria = tipo == TransactionType.ingreso ? 'Ventas Extra' : 'Servicios';
    final categorias = tipo == TransactionType.ingreso ? ['Ventas Extra', 'Aporte Capital', 'Préstamo', 'Otros'] : ['Servicios', 'Arriendo', 'Nómina', 'Proveedores', 'Mantenimiento', 'Otros'];

    // Colores Modal
    final modalBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.black;

    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: textColor),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 2.5)),
      );
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(color: modalBgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10))),
                          const SizedBox(height: 20),
                          Text(tipo == TransactionType.ingreso ? 'Nuevo Ingreso' : 'Nuevo Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tipo == TransactionType.ingreso ? Colors.green : Colors.red)),
                          const SizedBox(height: 20),
                          TextFormField(style: TextStyle(color: textColor), decoration: inputDecoration('Monto *', Icons.attach_money), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null, onSaved: (val) => monto = double.parse(val!)),
                          const SizedBox(height: 15),
                          TextFormField(style: TextStyle(color: textColor), decoration: inputDecoration('Descripción *', Icons.description), textCapitalization: TextCapitalization.sentences, validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null, onSaved: (val) => descripcion = val!),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            dropdownColor: modalBgColor,
                            style: TextStyle(color: textColor),
                            initialValue: categoria,
                            decoration: inputDecoration('Categoría', Icons.category),
                            items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor)))).toList(),
                            onChanged: (val) => categoria = val!,
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: tipo == TransactionType.ingreso ? Colors.green : Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      formKey.currentState!.save();
                                      ref.read(transactionsProvider.notifier).addTransaction(AppTransaction(
                                          id: const Uuid().v4(),
                                          tipo: tipo,
                                          monto: monto,
                                          fecha: DateTime.now(),
                                          descripcion: descripcion,
                                          categoria: categoria
                                      ));
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Guardar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                              )
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
  final Color bgColor;
  final Color textColor;

  const _InfoCard(this.title, this.amount, this.color, this.icon, this.bgColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color)
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          FittedBox(child: Text(currency.format(amount), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }
}
