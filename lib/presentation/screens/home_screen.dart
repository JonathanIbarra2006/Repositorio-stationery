import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../providers/date_range_provider.dart';
import '../widgets/flow_chart.dart';
import '../widgets/klip_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF121212) : kBg;

    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const KlipHeader(title: 'Klip', badge: 'PANEL DE INICIO'),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textColor))),
                data: (state) {
                  final transactions = state.transactions;
                  final ingresos = state.totalIngresos;
                  final gastos = state.totalGastos;
                  final patrimonio = state.balance;

                  final recientes = [...transactions]..sort((a, b) => b.fecha.compareTo(a.fecha));
                  final ultimos = recientes.take(10).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        ingresos: ingresos,
                        gastos: gastos,
                        patrimonio: patrimonio,
                        currency: currency,
                        dateLabel: dateRange.label,
                        onCalendarTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: dateRange.range,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: kAccent,
                                    onPrimary: Colors.white,
                                    surface: cardColor,
                                    onSurface: textColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            final label = '${DateFormat('d MMM').format(picked.start)} - ${DateFormat('d MMM').format(picked.end)}';
                            ref.read(dateRangeProvider.notifier).setRange(picked, label);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: FlowChart(
                          transactions: transactions,
                          range: dateRange.range,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Actividad Reciente', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 12),
                      if (ultimos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text('No hay movimientos en este periodo', style: TextStyle(color: subColor))),
                        ),
                      ...ultimos.map((t) => _ActivityTile(
                        transaction: t,
                        currency: currency,
                        cardColor: cardColor,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
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
}

class _SummaryCard extends StatelessWidget {
  final Color cardColor, textColor, subColor;
  final double ingresos, gastos, patrimonio;
  final NumberFormat currency;
  final String dateLabel;
  final VoidCallback onCalendarTap;

  const _SummaryCard({required this.cardColor, required this.textColor, required this.subColor, required this.ingresos, required this.gastos, required this.patrimonio, required this.currency, required this.dateLabel, required this.onCalendarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Acumulado Total', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
              GestureDetector(
                onTap: onCalendarTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kAccent.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: kAccent.withOpacity(0.3))),
                  child: Row(children: [const Icon(Icons.calendar_today, color: kAccent, size: 13), const SizedBox(width: 5), Text(dateLabel, style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 12))]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [const _StatPill(label: 'Ventas Totales', icon: Icons.trending_up, color: Colors.green), const SizedBox(width: 32), const _StatPill(label: 'Gastos Totales', icon: Icons.trending_down, color: kAccent)]),
          const SizedBox(height: 6),
          Row(children: [Text(currency.format(ingresos), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(width: 40), Text(currency.format(gastos), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor))]),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Patrimonio', style: TextStyle(color: subColor, fontSize: 13)), const SizedBox(height: 4), Text(currency.format(patrimonio), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: patrimonio >= 0 ? Colors.green : kAccent))]),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kAccent.withOpacity(0.10), shape: BoxShape.circle), child: const Icon(Icons.trending_up, color: kAccent, size: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill({required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 14)), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))]);
  }
}

class _ActivityTile extends StatelessWidget {
  final AppTransaction transaction;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  final bool isDark;
  const _ActivityTile({required this.transaction, required this.currency, required this.cardColor, required this.textColor, required this.subColor, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIngreso = t.tipo == TransactionType.ingreso;
    final timeStr = DateFormat('HH:mm').format(t.fecha);
    final color = isIngreso ? Colors.green : kAccent;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(isIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.descripcion, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)), const SizedBox(height: 3), Text('$timeStr · ${t.categoria}', style: TextStyle(color: subColor, fontSize: 12))])), Text(currency.format(t.monto), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color))]));
  }
}
