import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/database_helper.dart';
import '../../domain/models/transaction.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════════════

/// Estado de un fiado
enum EstadoFiado { pendiente, pagadoParcial, saldado }

/// Modelo de Cliente
class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final bool isActive;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.isActive = true,
  });
}

/// Modelo de un abono individual a un fiado
class AbonoFiado {
  final String id;
  final String fiadoId;
  final double monto;
  final DateTime fecha;
  final String? nota;

  AbonoFiado({
    required this.id,
    required this.fiadoId,
    required this.monto,
    required this.fecha,
    this.nota,
  });

  factory AbonoFiado.fromMap(Map<String, dynamic> map) => AbonoFiado(
        id: map['id'] as String,
        fiadoId: map['fiado_id'] as String,
        monto: (map['monto'] as num).toDouble(),
        fecha: DateTime.parse(map['fecha'] as String),
        nota: map['nota'] as String?,
      );
}

/// Modelo de un fiado (venta a crédito)
class Fiado {
  final String id;
  final String clienteId;
  final double total;
  final double montoPagado;
  final DateTime fecha;
  final EstadoFiado estado;
  final String? productos; // JSON string con los productos

  Fiado({
    required this.id,
    required this.clienteId,
    required this.total,
    required this.montoPagado,
    required this.fecha,
    required this.estado,
    this.productos,
  });

  double get saldoPendiente => total - montoPagado;

  factory Fiado.fromMap(Map<String, dynamic> map) {
    EstadoFiado estado;
    switch (map['estado'] as String) {
      case 'saldado':
        estado = EstadoFiado.saldado;
        break;
      case 'pagado_parcial':
        estado = EstadoFiado.pagadoParcial;
        break;
      default:
        estado = EstadoFiado.pendiente;
    }
    return Fiado(
      id: map['id'] as String,
      clienteId: map['cliente_id'] as String,
      total: (map['total'] as num).toDouble(),
      montoPagado: (map['monto_pagado'] as num? ?? 0).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      estado: estado,
      productos: map['productos'] as String?,
    );
  }

  Fiado copyWith({
    double? montoPagado,
    EstadoFiado? estado,
  }) {
    return Fiado(
      id: id,
      clienteId: clienteId,
      total: total,
      montoPagado: montoPagado ?? this.montoPagado,
      fecha: fecha,
      estado: estado ?? this.estado,
      productos: productos,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER DE CLIENTES
// ═══════════════════════════════════════════════════════════════

final clientesProvider =
    StateNotifierProvider<ClientesNotifier, AsyncValue<List<Cliente>>>((ref) {
  return ClientesNotifier();
});

class ClientesNotifier extends StateNotifier<AsyncValue<List<Cliente>>> {
  ClientesNotifier() : super(const AsyncValue.loading()) {
    loadClientes();
  }

  Future<void> loadClientes() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('clientes', orderBy: 'nombre ASC');
      final clientes = result
          .map((row) => Cliente(
                id: row['id'] as String,
                nombre: row['nombre'] as String,
                telefono: row['telefono'] as String?,
                email: row['email'] as String?,
                isActive: row['is_active'] == null || row['is_active'] == 1,
              ))
          .toList();
      state = AsyncValue.data(clientes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> desactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
    await loadClientes();
    return null;
  }

  Future<void> reactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'is_active': 1},
        where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  Future<void> eliminarClientePermanentemente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  Future<void> registrarNuevoClienteDirecto(
      String nombre, String telefono, String? email) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('clientes', {
      'id': const Uuid().v4(),
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'is_active': 1
    });
    await loadClientes();
  }

  Future<void> editarCliente(
      String id, String nuevoNombre, String nuevoTelefono,
      String? nuevoEmail) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
        'clientes',
        {
          'nombre': nuevoNombre,
          'telefono': nuevoTelefono,
          'email': nuevoEmail
        },
        where: 'id = ?',
        whereArgs: [id]);
    await loadClientes();
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER DE FIADOS
// ═══════════════════════════════════════════════════════════════

final fiadosProvider =
    StateNotifierProvider<FiadosNotifier, AsyncValue<List<Fiado>>>((ref) {
  return FiadosNotifier(ref);
});

class FiadosNotifier extends StateNotifier<AsyncValue<List<Fiado>>> {
  final Ref _ref;

  FiadosNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadFiados();
  }

  /// Carga todos los fiados (o solo los de un cliente)
  Future<void> loadFiados({String? clienteId}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'fiados',
        where: clienteId != null ? 'cliente_id = ?' : null,
        whereArgs: clienteId != null ? [clienteId] : null,
        orderBy: 'fecha DESC',
      );
      final fiados = result.map((r) => Fiado.fromMap(r)).toList();
      state = AsyncValue.data(fiados);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Retorna los fiados de un cliente específico (consulta directa, sin cambiar el state global)
  Future<List<Fiado>> getFiadosDeCliente(String clienteId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'fiados',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha DESC',
    );
    return result.map((r) => Fiado.fromMap(r)).toList();
  }

  /// Retorna los abonos de un fiado específico
  Future<List<AbonoFiado>> getAbonosDeFiado(String fiadoId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'abonos_fiados',
      where: 'fiado_id = ?',
      whereArgs: [fiadoId],
      orderBy: 'fecha DESC',
    );
    return result.map((r) => AbonoFiado.fromMap(r)).toList();
  }

  /// Retorna la deuda total pendiente de un cliente
  Future<double> getDeudaTotalCliente(String clienteId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(total - monto_pagado) as saldo FROM fiados WHERE cliente_id = ? AND estado != ?',
      [clienteId, 'saldado'],
    );
    if (result.isEmpty || result.first['saldo'] == null) return 0;
    return (result.first['saldo'] as num).toDouble();
  }

  /// Crea un nuevo fiado y registra la transacción correspondiente
  Future<String?> crearFiado({
    required String clienteId,
    required String nombreCliente,
    required double total,
    required String productosDescripcion,
    required List<Map<String, dynamic>> carritoItems, // [{productoId, nombre, cantidad, precio}]
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = const Uuid().v4();
      final fecha = DateTime.now();

      // 1. Insertar el fiado
      await db.insert('fiados', {
        'id': id,
        'cliente_id': clienteId,
        'total': total,
        'monto_pagado': 0.0,
        'fecha': fecha.toIso8601String(),
        'estado': 'pendiente',
        'productos': productosDescripcion,
      });

      // 2. Descontar stock de productos
      for (final item in carritoItems) {
        await db.rawUpdate(
          'UPDATE productos SET stock = stock - ? WHERE id = ?',
          [item['cantidad'], item['productoId']],
        );
      }

      // 3. Registrar transacción (ingreso pendiente - aparece en movimientos)
      final transaccion = AppTransaction(
        id: const Uuid().v4(),
        tipo: TransactionType.ingreso,
        monto: total,
        fecha: fecha,
        descripcion: 'Venta Fiada a $nombreCliente: $productosDescripcion',
        categoria: 'Ventas Fiadas',
        clienteId: clienteId,
      );
      await db.insert('transacciones', transaccion.toMap());

      await loadFiados();
      return null; // null = éxito
    } catch (e) {
      return 'Error al crear el fiado: $e';
    }
  }

  /// Registra un abono a un fiado existente
  Future<String?> registrarAbono({
    required String fiadoId,
    required String clienteId,
    required String nombreCliente,
    required double monto,
    String? nota,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final fecha = DateTime.now();

      // 1. Obtener el fiado actual
      final fiadoResult = await db.query(
        'fiados',
        where: 'id = ?',
        whereArgs: [fiadoId],
      );
      if (fiadoResult.isEmpty) return 'Fiado no encontrado';

      final fiado = Fiado.fromMap(fiadoResult.first);
      final nuevoMontoPagado = fiado.montoPagado + monto;

      if (monto > fiado.saldoPendiente) {
        return 'El abono (\$${monto.toStringAsFixed(0)}) supera el saldo pendiente (\$${fiado.saldoPendiente.toStringAsFixed(0)})';
      }

      // 2. Determinar nuevo estado
      String nuevoEstado;
      if (nuevoMontoPagado >= fiado.total) {
        nuevoEstado = 'saldado';
      } else if (nuevoMontoPagado > 0) {
        nuevoEstado = 'pagado_parcial';
      } else {
        nuevoEstado = 'pendiente';
      }

      // 3. Insertar abono
      await db.insert('abonos_fiados', {
        'id': const Uuid().v4(),
        'fiado_id': fiadoId,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'nota': nota,
      });

      // 4. Actualizar el fiado
      await db.update(
        'fiados',
        {'monto_pagado': nuevoMontoPagado, 'estado': nuevoEstado},
        where: 'id = ?',
        whereArgs: [fiadoId],
      );

      // 5. Registrar transacción (abono = ingreso de caja)
      final notaDescripcion = (nota != null && nota.isNotEmpty) ? ' ($nota)' : '';
      final transaccion = AppTransaction(
        id: const Uuid().v4(),
        tipo: TransactionType.ingreso,
        monto: monto,
        fecha: fecha,
        descripcion: 'Abono Fiado de $nombreCliente$notaDescripcion',
        categoria: 'Abonos Fiados',
        clienteId: clienteId,
      );
      await db.insert('transacciones', transaccion.toMap());

      // Recargar providers
      await loadFiados();
      _ref.invalidate(clientesProvider);

      return null; // null = éxito
    } catch (e) {
      return 'Error al registrar el abono: $e';
    }
  }
}