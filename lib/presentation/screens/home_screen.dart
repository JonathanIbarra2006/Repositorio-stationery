import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'settings_screen.dart'; // Importamos la pantalla de ajustes que acabamos de crear

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // Fechas para filtrar
    final now = DateTime.now();
    final todayStr = DateFormat('dd/MM/yyyy').format(now);
    final dayName = DateFormat('dd MMM', 'es_CO').format(now);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('InkTrack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          // AQUÍ MOVIMOS EL ÍCONO DE AJUSTES
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final transactions = state.transactions;

          // Filtramos solo movimientos de HOY
          final movimientosHoy = transactions.where((t) {
            final tDate = t.fecha;
            return DateFormat('dd/MM/yyyy').format(tDate) == todayStr;
          }).toList();

          double ingresosHoy = 0;
          double gastosHoy = 0;
          for (var t in movimientosHoy) {
            if (t.tipo == TransactionType.ingreso) {
              ingresosHoy += t.monto;
            } else {
              gastosHoy += t.monto;
            }
          }
          final balanceHoy = ingresosHoy - gastosHoy;

          // Historial reciente (últimos 5)
          final historial = [...transactions];
          historial.sort((a, b) => b.fecha.compareTo(a.fecha));
          final ultimos = historial.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resumen del día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Chip(label: Text(dayName), backgroundColor: Colors.blue.shade50)
                  ],
                ),
                const SizedBox(height: 15),

                // TARJETAS DE COLORES
                Row(
                  children: [
                    Expanded(child: _StatCard('Ingresos', ingresosHoy, Colors.orange, Icons.trending_up, currency)),
                    const SizedBox(width: 15),
                    Expanded(child: _StatCard('Gastos', gastosHoy, Colors.blue, Icons.trending_down, currency)),
                  ],
                ),
                const SizedBox(height: 15),

                // BALANCE NETO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.account_balance_wallet, color: Colors.blue), SizedBox(width: 10), Text('Balance Neto Hoy')]),
                      const SizedBox(height: 10),
                      Text(currency.format(balanceHoy), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const Text('Calculado sobre actividad de hoy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                const Text('Historial Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // LISTA HISTORIAL
                ...ultimos.map((t) {
                  final isIngreso = t.tipo == TransactionType.ingreso;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIngreso ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(isIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: isIngreso ? Colors.green : Colors.red),
                      ),
                      title: Text(t.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(DateFormat('HH:mm').format(t.fecha)),
                      trailing: Text(currency.format(t.monto), style: TextStyle(color: isIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currency;
  const _StatCard(this.title, this.amount, this.color, this.icon, this.currency);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(currency.format(amount), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
