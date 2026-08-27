import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/database_helper.dart';
import '../../domain/models/transaction.dart';
import 'dart:math';
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
  final String cedula;
  final String? telefono;
  final String? email;
  final bool isActive;

  Cliente({
    required this.id,
    required this.nombre,
    required this.cedula,
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
                cedula: row['cedula'] as String? ?? '',
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
      String nombre, String cedula, String telefono, String? email) async {
    final db = await DatabaseHelper.instance.database;
    
    // Validar cédula única (solo si no está vacía)
    if (cedula.trim().isNotEmpty) {
      final existing = await db.query('clientes', where: 'cedula = ?', whereArgs: [cedula]);
      if (existing.isNotEmpty) {
        throw Exception('Ya existe un cliente registrado con esta cédula.');
      }
    }

    final randomStr = Random().nextInt(99999999).toString().padLeft(8, '0');
    final customId = 'CLI-$randomStr';
    
    await db.insert('clientes', {
      'id': customId,
      'nombre': nombre,
      'cedula': cedula,
      'telefono': telefono,
      'email': email,
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await loadClientes();
  }

  Future<void> editarCliente(
      String id, String nuevoNombre, String nuevoCedula, String nuevoTelefono,
      String? nuevoEmail) async {
    final db = await DatabaseHelper.instance.database;
    
    // Validar cédula única (solo si no está vacía)
    if (nuevoCedula.trim().isNotEmpty) {
      final existing = await db.query('clientes', where: 'cedula = ? AND id != ?', whereArgs: [nuevoCedula, id]);
      if (existing.isNotEmpty) {
        throw Exception('Ya existe otro cliente registrado con esta cédula.');
      }
    }

    await db.update(
        'clientes',
        {
          'nombre': nuevoNombre,
          'cedula': nuevoCedula,
          'telefono': nuevoTelefono,
          'email': nuevoEmail,
          'updated_at': DateTime.now().toIso8601String(),
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

  /// Crea un nuevo fiado.
  /// NOTA: NO se registra transacción de ingreso aquí porque el dinero
  /// todavía no ha entrado a caja. El ingreso real se registra únicamente
  /// cuando el cliente realiza un abono (ver registrarAbono).
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

      await db.transaction((txn) async {
        // 1. Insertar el fiado
        await txn.insert('fiados', {
          'id': id,
          'cliente_id': clienteId,
          'total': total,
          'monto_pagado': 0.0,
          'fecha': fecha.toIso8601String(),
          'estado': 'pendiente',
          'productos': productosDescripcion,
          'updated_at': fecha.toIso8601String(),
        });

        // 2. Validar y descontar stock de productos
        for (final item in carritoItems) {
          final cantidad = item['cantidad'] as int;
          final productoId = item['productoId'] as String;
          final nombre = item['nombre'] ?? 'Producto';

          // Verificar stock disponible antes de descontar
          final stockResult = await txn.rawQuery(
            'SELECT stock FROM productos WHERE id = ?',
            [productoId],
          );
          if (stockResult.isEmpty) {
            throw Exception('Producto "$nombre" no encontrado en el inventario.');
          }
          final stockActual = stockResult.first['stock'] as int;
          if (stockActual < cantidad) {
            throw Exception('Stock insuficiente para "$nombre": disponible $stockActual, solicitado $cantidad.');
          }

          await txn.rawUpdate(
            'UPDATE productos SET stock = stock - ?, updated_at = ? WHERE id = ?',
            [cantidad, fecha.toIso8601String(), productoId],
          );
        }
      });

      // (No se inserta transacción aquí para evitar doble conteo.
      //  El ingreso se registra cuando el cliente abona.)

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

      await db.transaction((txn) async {
        // 1. Obtener el fiado actual
        final fiadoResult = await txn.query(
          'fiados',
          where: 'id = ?',
          whereArgs: [fiadoId],
        );
        if (fiadoResult.isEmpty) throw Exception('Fiado no encontrado');

        final fiado = Fiado.fromMap(fiadoResult.first);
        final nuevoMontoPagado = fiado.montoPagado + monto;

        if (monto > fiado.saldoPendiente) {
          throw Exception('El abono (\$${monto.toStringAsFixed(0)}) supera el saldo pendiente (\$${fiado.saldoPendiente.toStringAsFixed(0)})');
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
        await txn.insert('abonos_fiados', {
          'id': const Uuid().v4(),
          'fiado_id': fiadoId,
          'monto': monto,
          'fecha': fecha.toIso8601String(),
          'nota': nota,
          'updated_at': fecha.toIso8601String(),
        });

        // 4. Actualizar el fiado
        await txn.update(
          'fiados',
          {
            'monto_pagado': nuevoMontoPagado,
            'estado': nuevoEstado,
            'updated_at': fecha.toIso8601String(),
          },
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
        await txn.insert('transacciones', transaccion.toMap());
      });

      // Recargar providers
      await loadFiados();
      _ref.invalidate(clientesProvider);

      return null; // null = éxito
    } catch (e) {
      return 'Error al registrar el abono: $e';
    }
  }
}