import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/fiado_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

class CuentaClienteScreen extends ConsumerStatefulWidget {
  final Cliente cliente;

  const CuentaClienteScreen({super.key, required this.cliente});

  @override
  ConsumerState<CuentaClienteScreen> createState() =>
      _CuentaClienteScreenState();
}

class _CuentaClienteScreenState
    extends ConsumerState<CuentaClienteScreen> {
  List<Fiado> _fiados = [];
  bool _cargando = true;
  String? _errorMsg;

  final currency =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _cargarFiados();
  }

  Future<void> _cargarFiados() async {
    setState(() {
      _cargando = true;
      _errorMsg = null;
    });
    try {
      final fiados = await ref
          .read(fiadosProvider.notifier)
          .getFiadosDeCliente(widget.cliente.id);
      if (mounted) setState(() => _fiados = fiados);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _deudaTotal => _fiados.fold(0, (s, f) => s + f.saldoPendiente);
  double get _totalFiado => _fiados.fold(0, (s, f) => s + f.total);
  double get _totalAbonado => _fiados.fold(0, (s, f) => s + f.montoPagado);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final inicial = widget.cliente.nombre.isNotEmpty
        ? widget.cliente.nombre[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Cuenta del Cliente',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor)),
                        Text('HISTORIAL DE FIADOS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kWarning,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: kAccent),
                    onPressed: _cargarFiados,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),

            // ── Tarjeta resumen del cliente ───────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _deudaTotal > 0
                      ? [
                          kWarning.withValues(alpha: 0.9),
                          const Color(0xFFFF8C00),
                        ]
                      : [
                          kSuccess.withValues(alpha: 0.9),
                          const Color(0xFF059669),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (_deudaTotal > 0 ? kWarning : kSuccess)
                        .withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        child: Text(inicial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.cliente.nombre,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                            Text(
                              widget.cliente.telefono ?? 'Sin teléfono',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _deudaTotal > 0 ? 'CON DEUDA' : 'AL DÍA',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumenStat(
                          label: 'Total Fiado',
                          value: currency.format(_totalFiado),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      Expanded(
                        child: _ResumenStat(
                          label: 'Abonado',
                          value: currency.format(_totalAbonado),
                          icon: Icons.savings_outlined,
                        ),
                      ),
                      Expanded(
                        child: _ResumenStat(
                          label: 'Pendiente',
                          value: currency.format(_deudaTotal),
                          icon: Icons.schedule_outlined,
                          highlight: _deudaTotal > 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Título sección ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: kWarning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Historial de Fiados',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const Spacer(),
                  Text('${_fiados.length} registros',
                      style: TextStyle(color: subColor, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Lista de fiados ──────────────────────────────────
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: kWarning))
                  : _errorMsg != null
                      ? Center(
                          child: Text(_errorMsg!,
                              style: const TextStyle(color: kError)))
                      : _fiados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.handshake_outlined,
                                      size: 64,
                                      color: subColor.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text('Sin fiados registrados',
                                      style: TextStyle(
                                          color: subColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Este cliente no tiene deudas',
                                      style: TextStyle(
                                          color: subColor, fontSize: 13)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarFiados,
                              color: kWarning,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 100),
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                itemCount: _fiados.length,
                                itemBuilder: (ctx, i) => _FiadoCard(
                                  fiado: _fiados[i],
                                  cliente: widget.cliente,
                                  currency: currency,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  subColor: subColor,
                                  isDark: isDark,
                                  onAbonoRegistrado: _cargarFiados,
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET STAT DEL RESUMEN
// ─────────────────────────────────────────────────────────────
class _ResumenStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _ResumenStat({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon,
            color: Colors.white.withValues(alpha: 0.8), size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: highlight ? 15 : 14)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD DE UN FIADO
// ─────────────────────────────────────────────────────────────
class _FiadoCard extends ConsumerWidget {
  final Fiado fiado;
  final Cliente cliente;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  final bool isDark;
  final VoidCallback onAbonoRegistrado;

  const _FiadoCard({
    required this.fiado,
    required this.cliente,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.onAbonoRegistrado,
  });

  Color get _estadoColor {
    switch (fiado.estado) {
      case EstadoFiado.saldado:
        return kSuccess;
      case EstadoFiado.pagadoParcial:
        return kAccent;
      default:
        return kWarning;
    }
  }

  String get _estadoLabel {
    switch (fiado.estado) {
      case EstadoFiado.saldado:
        return 'Saldado ✓';
      case EstadoFiado.pagadoParcial:
        return 'Pago Parcial';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progreso = fiado.total > 0 ? (fiado.montoPagado / fiado.total) : 0.0;

    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _estadoColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila: fecha + estado
            Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: _estadoColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(fiado.fecha),
                  style: TextStyle(color: subColor, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _estadoLabel,
                    style: TextStyle(
                        color: _estadoColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descripción de productos
            if (fiado.productos != null && fiado.productos!.isNotEmpty)
              Text(
                fiado.productos!,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(_estadoColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 10),

            // Montos
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total',
                        style: TextStyle(color: subColor, fontSize: 11)),
                    Text(
                      currency.format(fiado.total),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abonado',
                        style: TextStyle(color: subColor, fontSize: 11)),
                    Text(
                      currency.format(fiado.montoPagado),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kSuccess,
                          fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                if (fiado.estado != EstadoFiado.saldado)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Pendiente',
                          style: TextStyle(color: subColor, fontSize: 11)),
                      Text(
                        currency.format(fiado.saldoPendiente),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kWarning,
                            fontSize: 15),
                      ),
                    ],
                  ),
              ],
            ),

            // Botón registrar abono (solo si no está saldado)
            if (fiado.estado != EstadoFiado.saldado) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kWarning,
                    side: BorderSide(
                        color: kWarning.withValues(alpha: 0.5), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Registrar Abono',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _mostrarBottomSheetAbono(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Muestra el bottom sheet para registrar un abono
  void _mostrarBottomSheetAbono(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AbonoBottomSheet(
        fiado: fiado,
        cliente: cliente,
        currency: currency,
        cardColor: cardColor,
        textColor: textColor,
        subColor: subColor,
        isDark: isDark,
        onAbonoRegistrado: onAbonoRegistrado,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM SHEET: FORMULARIO DE ABONO
// ─────────────────────────────────────────────────────────────
class _AbonoBottomSheet extends ConsumerStatefulWidget {
  final Fiado fiado;
  final Cliente cliente;
  final NumberFormat currency;
  final Color cardColor, textColor, subColor;
  final bool isDark;
  final VoidCallback onAbonoRegistrado;

  const _AbonoBottomSheet({
    required this.fiado,
    required this.cliente,
    required this.currency,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.onAbonoRegistrado,
  });

  @override
  ConsumerState<_AbonoBottomSheet> createState() =>
      _AbonoBottomSheetState();
}

class _AbonoBottomSheetState extends ConsumerState<_AbonoBottomSheet> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _procesando = false;
  String? _errorMonto;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarAbono() async {
    final monto = double.tryParse(
        _montoCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'\s'), ''));

    if (monto == null || monto <= 0) {
      setState(() => _errorMonto = 'Ingresa un monto válido mayor a cero');
      return;
    }
    if (monto > widget.fiado.saldoPendiente) {
      setState(() => _errorMonto =
          'El monto supera el saldo pendiente (${widget.currency.format(widget.fiado.saldoPendiente)})');
      return;
    }

    setState(() {
      _procesando = true;
      _errorMonto = null;
    });

    final nota = _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim();

    final error = await ref.read(fiadosProvider.notifier).registrarAbono(
          fiadoId: widget.fiado.id,
          clienteId: widget.cliente.id,
          nombreCliente: widget.cliente.nombre,
          monto: monto,
          nota: nota,
        );

    // Refrescar transacciones en finance screen
    ref.invalidate(transactionsProvider);

    if (!mounted) return;
    setState(() => _procesando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: kError),
      );
      return;
    }

    Navigator.pop(context);
    widget.onAbonoRegistrado();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Abono de ${widget.currency.format(monto)} registrado correctamente'),
            ),
          ],
        ),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.payment_rounded, color: kWarning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registrar Abono',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor)),
                    Text(
                      '${widget.cliente.nombre} · Pendiente: ${widget.currency.format(widget.fiado.saldoPendiente)}',
                      style:
                          TextStyle(color: widget.subColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Campo monto
          Text('MONTO DEL ABONO',
              style: TextStyle(
                  color: kWarning,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          TextField(
            controller: _montoCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]'))
            ],
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: widget.textColor),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle:
                  TextStyle(color: widget.subColor, fontWeight: FontWeight.w900),
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kWarning),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: kWarning, width: 2)),
              errorText: _errorMonto,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) {
              if (_errorMonto != null) setState(() => _errorMonto = null);
            },
          ),

          // Botón "Abonar Todo"
          if (widget.fiado.saldoPendiente > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _montoCtrl.text =
                    widget.fiado.saldoPendiente.toStringAsFixed(0);
                _errorMonto = null;
              }),
              child: Text(
                'Abonar todo el saldo (${widget.currency.format(widget.fiado.saldoPendiente)})',
                style: const TextStyle(
                    color: kAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Campo nota (opcional)
          Text('NOTA (OPCIONAL)',
              style: TextStyle(
                  color: widget.subColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          TextField(
            controller: _notaCtrl,
            style: TextStyle(color: widget.textColor),
            decoration: InputDecoration(
              hintText: 'Ej: Pago en efectivo, transferencia...',
              hintStyle: TextStyle(color: widget.subColor, fontSize: 13),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: kAccent, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kWarning,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: _procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _procesando ? 'Registrando...' : 'CONFIRMAR ABONO',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              onPressed: _procesando ? null : _confirmarAbono,
            ),
          ),
        ],
      ),
    );
  }
}
