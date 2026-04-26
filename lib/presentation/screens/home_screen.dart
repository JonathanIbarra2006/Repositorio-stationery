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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const KlipHeader(title: 'Klip', badge: 'PANEL DE INICIO'),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: colorScheme.onSurface))),
                data: (state) {
                  final transactions = state.transactions;
                  final ingresos = state.totalIngresos;
                  final gastos = state.totalGastos;
                  final patrimonio = state.balance;

                  final recientes = [...transactions]..sort((a, b) => b.fecha.compareTo(a.fecha));
                  final ultimos = recientes.take(10).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _SummaryCard(
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
                                data: theme.copyWith(
                                  colorScheme: colorScheme.copyWith(
                                    primary: kAccent,
                                    onPrimary: Colors.white,
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: kAccent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Flujo de Caja',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            FlowChart(
                              transactions: transactions,
                              range: dateRange.range,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Actividad Reciente', 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () {}, 
                            child: const Text('Ver todo', style: TextStyle(color: kAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (ultimos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                'No hay movimientos', 
                                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ...ultimos.map((t) => _ActivityTile(
                        transaction: t,
                        currency: currency,
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
  final double ingresos, gastos, patrimonio;
  final NumberFormat currency;
  final String dateLabel;
  final VoidCallback onCalendarTap;

  const _SummaryCard({
    required this.ingresos, 
    required this.gastos, 
    required this.patrimonio, 
    required this.currency, 
    required this.dateLabel, 
    required this.onCalendarTap
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
            blurRadius: 20, 
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acumulado', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              GestureDetector(
                onTap: onCalendarTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: kAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: kAccent, size: 14), 
                      const SizedBox(width: 6), 
                      Text(
                        dateLabel, 
                        style: const TextStyle(
                          color: kAccent, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatItem(label: 'Ingresos', value: currency.format(ingresos), icon: Icons.arrow_upward_rounded, color: kSuccess)),
              const SizedBox(width: 16),
              Expanded(child: _StatItem(label: 'Gastos', value: currency.format(gastos), icon: Icons.arrow_downward_rounded, color: kError)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text('Balance General', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600)), 
                  const SizedBox(height: 4), 
                  Text(
                    currency.format(patrimonio), 
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      color: patrimonio >= 0 ? kSuccess : kError,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(
                  color: (patrimonio >= 0 ? kSuccess : kError).withValues(alpha: 0.1), 
                  shape: BoxShape.circle,
                ), 
                child: Icon(
                  patrimonio >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, 
                  color: patrimonio >= 0 ? kSuccess : kError, 
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), 
              child: Icon(icon, color: color, size: 14),
            ), 
            const SizedBox(width: 8), 
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppTransaction transaction;
  final NumberFormat currency;
  final bool isDark;
  const _ActivityTile({required this.transaction, required this.currency, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = transaction;
    final isIngreso = t.tipo == TransactionType.ingreso;
    final timeStr = DateFormat('HH:mm').format(t.fecha);
    final color = isIngreso ? kSuccess : kError;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ), 
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), 
            child: Icon(isIngreso ? Icons.add_rounded : Icons.remove_rounded, color: color, size: 20),
          ), 
          const SizedBox(width: 16), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  t.descripcion, 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
                ), 
                const SizedBox(height: 4), 
                Text(
                  '$timeStr · ${t.categoria}', 
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ), 
          Text(
            currency.format(t.monto), 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}
