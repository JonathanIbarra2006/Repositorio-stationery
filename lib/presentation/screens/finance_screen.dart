import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/product_provider.dart';
import '../providers/fiado_provider.dart';
import '../providers/date_range_provider.dart';
import '../widgets/klip_header.dart';
import 'venta_contado_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  static const _accent = Color(0xFFEF4063);
  final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final transactionsAsync = ref.watch(transactionsProvider);
    final dateRange = ref.watch(dateRangeProvider);

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
                loading: () => const LinearProgressIndicator(color: _accent),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (state) => _FinancialSummaryCard(
                  state: state,
                  dateLabel: dateRange.label,
                  onDateTap: _selectDateRange,
                  cardColor: cardColor,
                  textColor: textColor,
                  subColor: subColor,
                  currency: currency,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: _accent,
                  indicatorWeight: 3,
                  labelColor: _accent,
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
                    _ResumenTab(currency: currency, textColor: textColor, subColor: subColor, cardColor: cardColor),
                    _MovimientosTab(currency: currency, textColor: textColor, subColor: subColor, cardColor: cardColor),
                    _InventarioTab(currency: currency, textColor: textColor, subColor: subColor, cardColor: cardColor),
                    _ClientesTab(currency: currency, textColor: textColor, subColor: subColor, cardColor: cardColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildSpeedDial(context, isDark),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context, bool isDark) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.point_of_sale),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          label: 'Venta de Contado',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentaDeContadoScreen())),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add_circle_outline),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'Ingreso Extra',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => _showTransactionModal(context, ref, 'ingreso', isDark),
        ),
        SpeedDialChild(
          child: const Icon(Icons.remove_circle_outline),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          label: 'Egreso / Gasto',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () => _showTransactionModal(context, ref, 'gasto', isDark),
        ),
      ],
    );
  }

  void _showTransactionModal(BuildContext context, WidgetRef ref, String tipoString, bool isDark) {
    final formKey = GlobalKey<FormState>();
    double monto = 0;
    String descripcion = '';
    final TransactionType tipo = tipoString == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto;
    String categoria = tipo == TransactionType.ingreso ? 'Ventas Extra' : 'Servicios';
    final categorias = tipo == TransactionType.ingreso ? ['Ventas Extra', 'Aporte Capital', 'Préstamo', 'Otros'] : ['Servicios', 'Arriendo', 'Nómina', 'Proveedores', 'Mantenimiento', 'Otros'];

    final modalBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: modalBgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(tipo == TransactionType.ingreso ? 'Nuevo Ingreso' : 'Nuevo Gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tipo == TransactionType.ingreso ? Colors.green : Colors.red)),
                const SizedBox(height: 24),
                TextFormField(decoration: _inputDecoration('Monto', Icons.attach_money, textColor, isDark), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null, onSaved: (v) => monto = double.parse(v!)),
                const SizedBox(height: 16),
                TextFormField(decoration: _inputDecoration('Descripción', Icons.description_outlined, textColor, isDark), textCapitalization: TextCapitalization.sentences, validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null, onSaved: (v) => descripcion = v!),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(value: categoria, dropdownColor: modalBgColor, decoration: _inputDecoration('Categoría', Icons.category_outlined, textColor, isDark), items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor)))).toList(), onChanged: (v) => categoria = v!),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 54, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: tipo == TransactionType.ingreso ? Colors.green : Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), onPressed: () { if (formKey.currentState!.validate()) { formKey.currentState!.save(); ref.read(transactionsProvider.notifier).addTransaction(AppTransaction(id: const Uuid().v4(), tipo: tipo, monto: monto, fecha: DateTime.now(), descripcion: descripcion, categoria: categoria)); Navigator.pop(ctx); } }, child: const Text('Guardar Movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color textColor, bool isDark) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon, color: _accent), filled: true, fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
  }

  void _selectDateRange() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime(2030), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _accent, onPrimary: Colors.white, onSurface: Colors.black87)), child: child!));
    if (range != null) {
      String label = 'Rango';
      final now = DateTime.now();
      if (range.start.day == now.day && range.start.month == now.month && range.start.year == now.year && range.end.day == now.day && range.end.month == now.month && range.end.year == now.year) { label = 'Hoy'; }
      ref.read(dateRangeProvider.notifier).setRange(range, label);
    }
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final TransactionState state;
  final String dateLabel;
  final VoidCallback onDateTap;
  final Color cardColor, textColor, subColor;
  final NumberFormat currency;

  const _FinancialSummaryCard({required this.state, required this.dateLabel, required this.onDateTap, required this.cardColor, required this.textColor, required this.subColor, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resumen\nFinanciero', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1, color: textColor)),
              GestureDetector(onTap: onDateTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFEF4063).withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.calendar_today_rounded, color: Color(0xFFEF4063), size: 14), const SizedBox(width: 8), Text(dateLabel, style: const TextStyle(color: Color(0xFFEF4063), fontWeight: FontWeight.bold, fontSize: 13))]))),
            ],
          ),
          const SizedBox(height: 24),
          Row(children: [_MiniStat(label: 'Ingresos', amount: state.totalIngresos, color: Colors.green, currency: currency), const SizedBox(width: 24), _MiniStat(label: 'Egresos', amount: state.totalGastos, color: const Color(0xFFEF4063), currency: currency)]),
          const SizedBox(height: 32),
          Text('Balance Neto', style: TextStyle(color: subColor, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(currency.format(state.balance), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: state.balance >= 0 ? Colors.green : const Color(0xFFEF4063))), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEF4063).withOpacity(0.05), shape: BoxShape.circle), child: const Icon(Icons.trending_up, color: Color(0xFFEF4063), size: 20))]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;
  const _MiniStat({required this.label, required this.amount, required this.color, required this.currency});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Icon(Icons.arrow_upward, color: color, size: 10)), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]), const SizedBox(height: 8), Text(currency.format(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]);
  }
}

class _ResumenTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color textColor, subColor, cardColor;
  const _ResumenTab({required this.currency, required this.textColor, required this.subColor, required this.cardColor});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsProvider);
    final clientesAsync = ref.watch(clientesProvider);

    return transAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
            if (dist.isEmpty) _EmptyTab(label: 'Sin datos de ingresos', subColor: subColor) else Container(height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 50, sections: dist.entries.map((e) { final colors = [const Color(0xFFEF4063), Colors.orange, Colors.teal, Colors.blue, Colors.purple]; final index = dist.keys.toList().indexOf(e.key) % colors.length; return PieChartSectionData(value: e.value, title: '${((e.value / (state.totalIngresos == 0 ? 1 : state.totalIngresos)) * 100).toStringAsFixed(0)}%', color: colors[index], radius: 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)); }).toList()))),
            const SizedBox(height: 24),
            Text('Leyenda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
            const SizedBox(height: 10),
            ...dist.entries.map((e) { final colors = [const Color(0xFFEF4063), Colors.orange, Colors.teal, Colors.blue, Colors.purple]; final index = dist.keys.toList().indexOf(e.key) % colors.length; return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index], shape: BoxShape.circle)), const SizedBox(width: 8), Text(e.key, style: TextStyle(color: textColor, fontSize: 13)), const Spacer(), Text(currency.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold))])); }),
            const SizedBox(height: 32),
            Text('Top Clientes (Ventas)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error al cargar clientes: $e'),
              data: (clientes) {
                if (sortedTop.isEmpty) return _EmptyTab(label: 'Sin ventas a clientes registrados', subColor: subColor);
                return Column(
                  children: sortedTop.take(5).map((entry) {
                    final cliente = clientes.firstWhere((c) => c.id == entry.key, orElse: () => throw 'Cliente no encontrado');
                    return _TopClienteItem(name: cliente.nombre, id: cliente.id.substring(0, 8), amount: entry.value, currency: currency, cardColor: cardColor, textColor: textColor, subColor: subColor);
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
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFFEF4063).withOpacity(0.1), child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFEF4063), fontWeight: FontWeight.bold))), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), Text('ID: $id', style: TextStyle(color: subColor, fontSize: 12))]), const Spacer(), Text(currency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]));
  }
}

class _MovimientosTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color textColor, subColor, cardColor;
  const _MovimientosTab({required this.currency, required this.textColor, required this.subColor, required this.cardColor});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsProvider);
    return transAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.transactions.isEmpty) return _EmptyTab(label: 'Sin movimientos', subColor: subColor);
        final list = [...state.transactions];
        list.sort((a, b) => b.fecha.compareTo(a.fecha));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final t = list[index];
            final isIngreso = t.tipo == TransactionType.ingreso;
            return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isIngreso ? Colors.green : const Color(0xFFEF4063)).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(isIngreso ? Icons.arrow_downward : Icons.arrow_upward, color: isIngreso ? Colors.green : const Color(0xFFEF4063), size: 20)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.descripcion, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), Text(DateFormat('dd/MM/yyyy HH:mm').format(t.fecha), style: TextStyle(color: subColor, fontSize: 12))])), Text('${isIngreso ? '' : '- '}${currency.format(t.monto)}', style: TextStyle(fontWeight: FontWeight.w900, color: isIngreso ? Colors.green : const Color(0xFFEF4063)))]));
          },
        );
      },
    );
  }
}

class _InventarioTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color textColor, subColor, cardColor;
  const _InventarioTab({required this.currency, required this.textColor, required this.subColor, required this.cardColor});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        if (products.isEmpty) return _EmptyTab(label: 'Sin productos', subColor: subColor);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEF4063).withOpacity(0.08), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFEF4063), size: 20)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), Text('Stock: ${p.stock} | ${p.categoria}', style: TextStyle(color: subColor, fontSize: 12))])), Text(currency.format(p.precio), style: const TextStyle(fontWeight: FontWeight.w900))]));
          },
        );
      },
    );
  }
}

class _ClientesTab extends ConsumerWidget {
  final NumberFormat currency;
  final Color textColor, subColor, cardColor;
  const _ClientesTab({required this.currency, required this.textColor, required this.subColor, required this.cardColor});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesProvider);
    return clientesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (clientes) {
        if (clientes.isEmpty) return _EmptyTab(label: 'Sin clientes', subColor: subColor);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final c = clientes[index];
            return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(backgroundColor: const Color(0xFFEF4063).withOpacity(0.1), child: Text(c.nombre[0].toUpperCase(), style: const TextStyle(color: Color(0xFFEF4063), fontWeight: FontWeight.bold))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.nombre, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)), Text(c.telefono ?? 'Sin teléfono', style: TextStyle(color: subColor, fontSize: 12))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(currency.format(c.deuda), style: TextStyle(fontWeight: FontWeight.w900, color: c.deuda > 0 ? Colors.orange : Colors.green)), if (c.deuda > 0) const Text('FIADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))])]));
          },
        );
      },
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;
  final Color subColor;
  const _EmptyTab({required this.label, required this.subColor});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, size: 48, color: subColor.withOpacity(0.5)), const SizedBox(height: 12), Text(label, style: TextStyle(color: subColor))]));
  }
}
