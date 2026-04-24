import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/database_helper.dart';
import '../../domain/models/product.dart';

// --- MODELOS ---
class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final double deuda;
  final bool isActive;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.deuda = 0.0,
    this.isActive = true,
  });
}

class FiadoDetalle {
  final String id;
  final double total;
  final double montoPagado; // Nuevo campo
  final String fecha;
  final String estado;
  final String productos;

  FiadoDetalle({
    required this.id,
    required this.total,
    required this.montoPagado, // Nuevo
    required this.fecha,
    required this.estado,
    required this.productos
  });

  // Calculamos dinámicamente cuánto debe
  double get saldoPendiente => total - montoPagado;
}

// --- PROVIDER ---
final clientesProvider = StateNotifierProvider<ClientesNotifier, AsyncValue<List<Cliente>>>((ref) {
  return ClientesNotifier();
});

class ClientesNotifier extends StateNotifier<AsyncValue<List<Cliente>>> {
  ClientesNotifier() : super(const AsyncValue.loading()) {
    loadClientes();
  }

  Future<void> loadClientes({bool includeInactive = true}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final whereClause = includeInactive ? '' : 'WHERE c.is_active = 1';
      
      // SQL Pro: Traemos el cliente y sumamos su deuda pendiente en una sola consulta
      final result = await db.rawQuery('''
        SELECT c.*, 
          (SELECT TOTAL(f.total - f.monto_pagado) 
           FROM fiados f 
           WHERE f.cliente_id = c.id AND f.estado = 'pendiente') as deuda
        FROM clientes c
        $whereClause
        ORDER BY c.nombre ASC
      ''');

      final clientes = result.map((row) => Cliente(
        id: row['id'] as String,
        nombre: row['nombre'] as String,
        telefono: row['telefono'] as String?,
        email: row['email'] as String?,
        deuda: (row['deuda'] as num?)?.toDouble() ?? 0.0,
        isActive: row['is_active'] == null || row['is_active'] == 1,
      )).toList();
      state = AsyncValue.data(clientes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- OBTENER HISTORIAL CON ABONOS ---
  Future<List<FiadoDetalle>> obtenerHistorialCliente(String clienteId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
        'fiados',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        orderBy: "fecha DESC"
    );

    return result.map((r) => FiadoDetalle(
      id: r['id'] as String,
      total: r['total'] as double,
      montoPagado: (r['monto_pagado'] as num?)?.toDouble() ?? 0.0, // Leemos lo pagado
      fecha: r['fecha'] as String,
      estado: r['estado'] as String,
      productos: r['productos'] as String,
    )).toList();
  }

  // --- NUEVA LÓGICA: REGISTRAR ABONO ---
  Future<void> registrarAbono({
    required String fiadoId,
    required double abono,
    required double totalDeuda,
    required double loQueYaPago,
    required String nombreCliente
  }) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Calculamos el nuevo acumulado
    final nuevoPagado = loQueYaPago + abono;

    // 2. Determinamos si ya pagó todo (permitimos margen de error de centavos)
    final nuevoEstado = (nuevoPagado >= totalDeuda) ? 'pagado' : 'pendiente';

    await db.transaction((txn) async {
      // A. Actualizar Fiado
      await txn.update(
          'fiados',
          {
            'monto_pagado': nuevoPagado,
            'estado': nuevoEstado
          },
          where: 'id = ?',
          whereArgs: [fiadoId]
      );

      // B. REGISTRAR EL INGRESO EN CAJA (Solo lo que abonó hoy)
      await txn.insert('transacciones', {
        'id': const Uuid().v4(),
        'tipo': 'ingreso',
        'monto': abono, // Solo registramos el abono, no el total
        'fecha': DateTime.now().toIso8601String(),
        'descripcion': 'Abono de: $nombreCliente',
        'categoria': 'Recaudo Cartera'
      });
    });
  }

  // --- DESACTIVAR CLIENTE (En lugar de eliminar) ---
  Future<String?> desactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    
    // Verificamos si tiene deudas pendientes
    final countResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM fiados WHERE cliente_id = ? AND estado = 'pendiente'",
      [id]
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    
    if (count > 0) {
      return "No se puede desactivar un cliente con deudas pendientes.";
    }

    await db.update('clientes', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
    await loadClientes();
    return null;
  }

  Future<void> reactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'is_active': 1}, where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  Future<void> eliminarClientePermanentemente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  // --- REGISTRAR FIADO ---
  Future<void> registrarFiado({
    String? clienteIdExistente, String? nombreNuevo, String? telefonoNuevo,
    required Map<Product, int> carrito, required double totalDeuda,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final fiadoId = const Uuid().v4();
    final fecha = DateTime.now().toIso8601String();
    final descripcionProductos = carrito.entries.map((e) => "${e.value}x ${e.key.nombre}").join(", ");

    await db.transaction((txn) async {
      String finalClienteId;
      if (clienteIdExistente != null) {
        finalClienteId = clienteIdExistente;
      } else {
        finalClienteId = const Uuid().v4();
        await txn.insert('clientes', {'id': finalClienteId, 'nombre': nombreNuevo, 'telefono': telefonoNuevo});
      }

      await txn.insert('fiados', {
        'id': fiadoId, 'cliente_id': finalClienteId,
        'total': totalDeuda, 'monto_pagado': 0, // Inicia debiendo todo
        'fecha': fecha, 'estado': 'pendiente', 'productos': descripcionProductos,
      });

      for (var entry in carrito.entries) {
        final nuevoStock = entry.key.stock - entry.value;
        await txn.update('productos', {'stock': nuevoStock}, where: 'id = ?', whereArgs: [entry.key.id]);
      }
    });
    await loadClientes();
  }

  Future<void> registrarNuevoClienteDirecto(String nombre, String telefono, String? email) async {
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

  // Volvemos a poner editarCliente aquí abajo
  Future<void> editarCliente(String id, String nuevoNombre, String nuevoTelefono, String? nuevoEmail) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {
      'nombre': nuevoNombre,
      'telefono': nuevoTelefono,
      'email': nuevoEmail
    }, where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }
}

// ────────────────────────────────────────────────
// ESTADÍSTICAS DE CARTERA
// ────────────────────────────────────────────────
class CarteraStats {
  final int totalClientes;
  final int clientesConDeuda;
  final double deudaTotal;

  const CarteraStats({
    required this.totalClientes,
    required this.clientesConDeuda,
    required this.deudaTotal,
  });
}

final carteraStatsProvider = FutureProvider<CarteraStats>((ref) async {
  // Escuchar cambios en clientes para refrescar
  ref.watch(clientesProvider);

  final db = await DatabaseHelper.instance.database;
  final clientes = await db.query('clientes', where: 'is_active = 1');
  final fiados = await db.query('fiados', where: "estado = 'pendiente'");
// ... (rest of stats logic)

  final Set<String> idsConDeuda = {};
  double deudaTotal = 0;

  for (final f in fiados) {
    final total = (f['total'] as num).toDouble();
    final pagado = (f['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final saldo = total - pagado;
    if (saldo > 0.01) {
      idsConDeuda.add(f['cliente_id'] as String);
      deudaTotal += saldo;
    }
  }

  return CarteraStats(
    totalClientes: clientes.length,
    clientesConDeuda: idsConDeuda.length,
    deudaTotal: deudaTotal,
  );
});