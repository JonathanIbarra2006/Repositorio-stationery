import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../theme/app_colors.dart';

class FlowChart extends StatelessWidget {
  final List<AppTransaction> transactions;
  final DateTimeRange? range;
  final bool isDark;

  const FlowChart({
    super.key,
    required this.transactions,
    this.range,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black54;
    
    // Preparar datos
    final Map<String, double> ingresosMap = {};
    final Map<String, double> egresosMap = {};

    DateTime start = range?.start ?? DateTime.now().subtract(const Duration(days: 6));
    DateTime end = range?.end ?? DateTime.now();

    // Si el rango es de solo un día (ej. "Hoy"), mostramos los últimos 7 días en el gráfico
    // para que la tendencia tenga sentido visualmente.
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      start = end.subtract(const Duration(days: 6));
    }

    // Normalizar fechas a medianoche para comparación
    start = DateTime(start.year, start.month, start.day);
    end = DateTime(end.year, end.month, end.day);

    final daysCount = end.difference(start).inDays + 1;
    final List<DateTime> days = List.generate(
      daysCount,
      (index) => start.add(Duration(days: index)),
    );

    for (var day in days) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      ingresosMap[key] = 0;
      egresosMap[key] = 0;
    }

    for (var t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.fecha);
      if (ingresosMap.containsKey(key)) {
        if (t.tipo == TransactionType.ingreso) {
          ingresosMap[key] = (ingresosMap[key] ?? 0) + t.monto;
        } else {
          egresosMap[key] = (egresosMap[key] ?? 0) + t.monto;
        }
      }
    }

    double maxVal = 0;
    final List<FlSpot> ingresosSpots = [];
    final List<FlSpot> egresosSpots = [];

    for (int i = 0; i < days.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(days[i]);
      final ing = ingresosMap[key] ?? 0;
      final egr = egresosMap[key] ?? 0;
      
      ingresosSpots.add(FlSpot(i.toDouble(), ing));
      egresosSpots.add(FlSpot(i.toDouble(), egr));

      if (ing > maxVal) maxVal = ing;
      if (egr > maxVal) maxVal = egr;
    }

    // Ajustar maxVal para que el gráfico no toque el tope
    maxVal = maxVal == 0 ? 1000 : maxVal * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                range == null ? 'Tendencia (Últimos 7 días)' : 'Tendencia del Periodo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Indicator(color: Colors.green, text: 'Ingresos'),
                const SizedBox(width: 12),
                _Indicator(color: kAccent, text: 'Egresos'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) return const SizedBox();
                      
                      // Si hay muchos días, mostrar solo algunos labels
                      if (days.length > 10 && index % (days.length / 5).ceil() != 0) {
                        return const SizedBox();
                      }

                      final date = days[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('E', 'es_CO').format(date).substring(0, 1).toUpperCase(),
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxVal / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return Text('0', style: TextStyle(color: textColor, fontSize: 10));
                      if (value >= 1000) {
                        return Text('${(value / 1000).toStringAsFixed(1)}K', 
                          style: TextStyle(color: textColor, fontSize: 10));
                      }
                      return Text(value.toStringAsFixed(0), 
                        style: TextStyle(color: textColor, fontSize: 10));
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (days.length - 1).toDouble(),
              minY: 0,
              maxY: maxVal,
              lineBarsData: [
                LineChartBarData(
                  spots: ingresosSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: egresosSpots,
                  isCurved: true,
                  color: kAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: kAccent.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
