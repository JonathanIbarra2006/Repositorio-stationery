import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Providers y Pantallas
import '../../domain/models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // --- LÓGICA DE MODO OSCURO (ALTO CONTRASTE) ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores Adaptables
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // TEXTOS: Aquí está la corrección principal
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[300] : Colors.grey[600]; // Gris claro en modo oscuro para que se lea

    // Tarjeta Balance (Azul claro en día, Azul profundo en noche)
    final balanceCardColor = isDark ? const Color(0xFF0D47A1) : const Color(0xFFE3F2FD);
    final balanceTextColor = isDark ? Colors.white : const Color(0xFF1565C0);
    final balanceSubTextColor = isDark ? Colors.white70 : Colors.black54;
    final balanceIconBg = isDark ? Colors.white24 : Colors.blue.withValues(alpha: 0.2);

    // Fechas
    final now = DateTime.now();
    final todayStr = DateFormat('dd/MM/yyyy').format(now);
    final dayName = DateFormat('dd MMM', 'es_CO').format(now);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.transparent, // AppBar visible en dark mode
        elevation: 0,
        centerTitle: true,
        title: Text(
            'InkTrack',
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 24
            )
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  shape: BoxShape.circle
              ),
              child: Icon(Icons.settings, color: textColor, size: 20),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: textColor))),
        data: (state) {
          final transactions = state.transactions;

          // 1. FILTRADO
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

          final historialReciente = [...transactions];
          historialReciente.sort((a, b) => b.fecha.compareTo(a.fecha));
          final ultimosMovimientos = historialReciente.take(10).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABECERA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resumen del día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(dayName, style: TextStyle(color: isDark ? Colors.blueAccent : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // TARJETAS COLORES (Ingresos/Gastos)
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: 'Ingresos\nTotales',
                        amount: ingresosHoy,
                        color: const Color(0xFFFFA726), // Naranja se mantiene igual
                        icon: Icons.trending_up,
                        currency: currency,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _DashboardCard(
                        title: 'Gastos\nTotales',
                        amount: gastosHoy,
                        color: const Color(0xFF2962FF), // Azul Rey se mantiene igual
                        icon: Icons.trending_down,
                        currency: currency,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // BALANCE NETO (ADAPTADO A MODO OSCURO)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: balanceCardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: balanceIconBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.account_balance_wallet, color: balanceTextColor),
                          ),
                          const SizedBox(width: 10),
                          Text('Balance Neto Hoy', style: TextStyle(color: balanceSubTextColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        currency.format(balanceHoy),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            // Si es negativo en modo oscuro, usamos rojo claro (Salmon) para que se vea
                            color: balanceHoy >= 0
                                ? balanceTextColor
                                : (isDark ? const Color(0xFFFF8A80) : Colors.red)
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('Calculado sobre ingresos y egresos de hoy', style: TextStyle(color: balanceSubTextColor, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Text('Historial de Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 15),

                // LISTA DE ACTIVIDAD
                if (ultimosMovimientos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text("No hay movimientos recientes", style: TextStyle(color: subTextColor))),
                  ),

                ...ultimosMovimientos.map((t) {
                  final isIngreso = t.tipo == TransactionType.ingreso;
                  final dateObj = t.fecha;
                  final timeStr = DateFormat('HH:mm').format(dateObj);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: cardColor, // Fondo oscuro en modo noche
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isIngreso
                                  ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.1))
                                  : (isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1)),
                              shape: BoxShape.circle
                          ),
                          child: Icon(
                            isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isIngreso ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  t.descripcion,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '$timeStr · ${t.categoria}',
                                  style: TextStyle(color: subTextColor, fontSize: 13) // AQUÍ ESTABA EL PROBLEMA (Gris claro ahora)
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currency.format(t.monto),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIngreso ? Colors.green : Colors.red
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat currency;

  const _DashboardCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.2)),
              const SizedBox(height: 8),
              Text(currency.format(amount), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
