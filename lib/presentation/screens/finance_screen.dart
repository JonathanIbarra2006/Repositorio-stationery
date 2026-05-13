import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/product_provider.dart';
import '../providers/fiado_provider.dart';
import '../providers/date_range_provider.dart';
import '../widgets/klip_header.dart';
import '../theme/app_colors.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/excel_generator.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final dateRange = ref.watch(dateRangeProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KlipHeader(title: 'Klip', badge: 'REPORTES DE NEGOCIO'),
              transactionsAsync.when(
                loading: () => const LinearProgressIndicator(color: kAccent),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (state) => _FinancialSummaryCard(
                  state: state,
                  dateLabel: dateRange.label,
                  onDateTap: _selectDateRange,
                  currency: currency,
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: kAccent,
                  indicatorWeight: 3,
                  labelColor: kAccent,
                  unselectedLabelColor: subColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Resumen'),
                    Tab(text: 'Movimientos'),
                    Tab(text: 'Inventario'),
                    Tab(text: 'Clientes'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    _ResumenTab(currency: currency, cardColor: cardColor, textColor: textColor, subColor: subColor),
                    _MovimientosTab(currency: currency, cardColor: cardColor, textColor: textColor, subColor: subColor),
                    _InventarioTab(currency: currency, cardColor: cardColor, textColor: textColor, subColor: subColor),
                    _ClientesTab(currency: currency, cardColor: cardColor, textColor: textColor, subColor: subColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildExportSpeedDial(context, ref),
      ),
    );
  }

  Widget _buildExportSpeedDial(BuildContext context, WidgetRef ref) {
    final List<AppTransaction> transactions = ref.watch(transactionsProvider).maybeWhen(
      data: (state) => state.transactions,
      orElse: () => <AppTransaction>[],
    );

    return SpeedDial(
      icon: Icons.ios_share_rounded,
      activeIcon: Icons.close_rounded,
      backgroundColor: kAccent,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.7,
      spacing: 15,
      spaceBetweenChildren: 12,
      childPadding: const EdgeInsets.all(4),
      buttonSize: const Size(60, 60),
      childrenButtonSize: const Size(56, 56),
      elevation: 8,
      animationCurve: Curves.elasticOut,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.picture_as_pdf_rounded, size: 28),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          label: 'Exportar PDF',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          labelBackgroundColor: Colors.redAccent,
          onTap: () => PdfGenerator.generateFinanceReport(transactions),
        ),
        SpeedDialChild(
          child: const Icon(Icons.table_chart_rounded, size: 28),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          label: 'Exportar Excel',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          labelBackgroundColor: Colors.green,
          onTap: () => ExcelGenerator.generateFinanceReport(transactions),
        ),
      ],
    );
  }


  void _selectDateRange() async {
    final dateRange = ref.read(dateRangeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: dateRange.range,
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: colorScheme.copyWith(
            primary: kAccent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final label = '${DateFormat('d MMM').format(picked.start)} - ${DateFormat('d MMM').format(picked.end)}';
      ref.read(dateRangeProvider.notifier).setRange(picked, label);
    }
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final TransactionState state;
  final String dateLabel;
  final VoidCallback onDateTap;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  final bool isDark;

  const _FinancialSummaryCard({
    required this.state, 
    required this.dateLabel, 
    required this.onDateTap, 
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
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
              Text('Resumen\nFinanciero',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: textColor)),
              GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kAccent.withValues(alpha: 0.2))),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: kAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(dateLabel, style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 13))
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _StatItem(
                label: 'Ingresos',
                value: currency.format(state.totalIngresos),
                icon: Icons.arrow_downward,
                color: kSuccess,
              ),
              const Spacer(),
              _StatItem(
                label: 'Egresos',
                value: currency.format(state.totalGastos),
                icon: Icons.arrow_upward,
                color: kError,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance Neto', style: TextStyle(color: subColor, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(state.balance),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: state.balance >= 0 ? kSuccess : kError),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (state.balance >= 0 ? kSuccess : kError).withValues(alpha: 0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    state.balance >= 0 ? Icons.trending_up : Icons.trending_down, 
                    color: state.balance >= 0 ? kSuccess : kError, 
                    size: 24
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ResumenTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  const _ResumenTab({required this.currency, required this.cardColor, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsProvider);
    final clientesAsync = ref.watch(clientesProvider);

    return transAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        final Map<String, double> dist = {};
        final Map<String, double> topClientesMap = {};
        
        for (var t in state.transactions) {
          if (t.tipo == TransactionType.ingreso) {
            final cat = t.categoria ?? 'Otros';
            dist[cat] = (dist[cat] ?? 0) + t.monto;
            
            if (t.clienteId != null) {
              topClientesMap[t.clienteId!] = (topClientesMap[t.clienteId!] ?? 0) + t.monto;
            }
          }
        }

        final sortedTop = topClientesMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          children: [
            const SizedBox(height: 10),
            Text('Distribución por Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            if (dist.isEmpty) 
              const _EmptyTab(label: 'Sin datos de ingresos') 
            else 
              Container(
                height: 220, 
                padding: const EdgeInsets.all(24), 
                decoration: BoxDecoration(
                  color: cardColor, 
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ), 
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4, 
                    centerSpaceRadius: 50, 
                    sections: dist.entries.map((e) { 
                      final colors = [kAccent, Colors.orange, Colors.teal, Colors.purple, Colors.pink]; 
                      final index = dist.keys.toList().indexOf(e.key) % colors.length; 
                      return PieChartSectionData(
                        value: e.value, 
                        title: '${((e.value / (state.totalIngresos == 0 ? 1 : state.totalIngresos)) * 100).toStringAsFixed(0)}%', 
                        color: colors[index], 
                        radius: 30, 
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                      ); 
                    }).toList()
                  )
                )
              ),
            const SizedBox(height: 24),
            Text('Leyenda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
            const SizedBox(height: 12),
            ...dist.entries.map((e) { 
              final colors = [kAccent, Colors.orange, Colors.teal, Colors.purple, Colors.pink]; 
              final index = dist.keys.toList().indexOf(e.key) % colors.length; 
              return Padding(
                padding: const EdgeInsets.only(bottom: 8), 
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index], shape: BoxShape.circle)), 
                    const SizedBox(width: 12), 
                    Text(e.key, style: TextStyle(color: textColor, fontSize: 13)), 
                    const Spacer(), 
                    Text(currency.format(e.value), style: TextStyle(fontWeight: FontWeight.bold, color: textColor))
                  ]
                )
              ); 
            }),
            const SizedBox(height: 32),
            Text('Top Clientes (Ventas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
              error: (e, _) => Text('Error al cargar clientes: $e', style: const TextStyle(color: kError)),
              data: (clientes) {
                if (sortedTop.isEmpty) return const _EmptyTab(label: 'Sin ventas a clientes registrados');
                return Column(
                  children: sortedTop.take(5).map((entry) {
                    final cliente = clientes.firstWhere((c) => c.id == entry.key, orElse: () => throw 'Cliente no encontrado');
                    return _TopClienteItem(
                      name: cliente.nombre, 
                      id: cliente.id.substring(0, 8), 
                      amount: entry.value, 
                      currency: currency,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _TopClienteItem extends StatelessWidget {
  final String name, id;
  final double amount;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  const _TopClienteItem({required this.name, required this.id, required this.amount, required this.currency, required this.cardColor, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
      ), 
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kAccent.withValues(alpha: 0.1), 
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold))
          ), 
          const SizedBox(width: 16), 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), 
              Text('ID: $id', style: TextStyle(color: subColor, fontSize: 12))
            ]
          ), 
          const Spacer(), 
          Text(currency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: kSuccess))
        ]
      )
    );
  }
}

class _MovimientosTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  const _MovimientosTab({required this.currency, required this.cardColor, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsProvider);
    return transAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.transactions.isEmpty) return const _EmptyTab(label: 'Sin movimientos');
        final list = [...state.transactions];
        list.sort((a, b) => b.fecha.compareTo(a.fecha));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final t = list[index];
            final isIngreso = t.tipo == TransactionType.ingreso;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), 
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
              ), 
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(
                      color: (isIngreso ? kSuccess : kError).withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(16)
                    ), 
                    child: Icon(isIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIngreso ? kSuccess : kError, size: 20)
                  ), 
                  const SizedBox(width: 16), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(t.descripcion, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), 
                        Text(DateFormat('dd/MM/yyyy HH:mm').format(t.fecha), style: TextStyle(color: subColor, fontSize: 12))
                      ]
                    )
                  ), 
                  Text(
                    '${isIngreso ? '' : '- '}${currency.format(t.monto)}', 
                    style: TextStyle(fontWeight: FontWeight.w900, color: isIngreso ? kSuccess : kError, fontSize: 16)
                  )
                ]
              )
            );
          },
        );
      },
    );
  }
}

class _InventarioTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  const _InventarioTab({required this.currency, required this.cardColor, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        if (products.isEmpty) return const _EmptyTab(label: 'Sin productos');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12), 
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
              ), 
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: kAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), 
                    child: const Icon(Icons.inventory_2_outlined, color: kAccent, size: 20)
                  ), 
                  const SizedBox(width: 16), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), 
                        Text('Stock: ${p.stock} | ${p.categoria}', style: TextStyle(color: subColor, fontSize: 12))
                      ]
                    )
                  ), 
                  Text(currency.format(p.precio), style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 16))
                ]
              )
            );
          },
        );
      },
    );
  }
}

class _ClientesTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  const _ClientesTab({required this.currency, required this.cardColor, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesProvider);
    return clientesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccent)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clientes) {
        if (clientes.isEmpty) return const _EmptyTab(label: 'Sin clientes');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final c = clientes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12), 
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
              ), 
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kAccent.withValues(alpha: 0.1), 
                    child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold))
                  ), 
                  const SizedBox(width: 16), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(c.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), 
                        Text(c.telefono ?? 'Sin teléfono', style: TextStyle(color: subColor, fontSize: 12))
                      ]
                    )
                  ), 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end, 
                    children: [
                      Text(currency.format(c.deuda), style: TextStyle(fontWeight: FontWeight.w900, color: c.deuda > 0 ? Colors.orange : kSuccess, fontSize: 16)), 
                      if (c.deuda > 0) const Text('FIADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))
                    ]
                  )
                ]
              )
            );
          },
        );
      },
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
