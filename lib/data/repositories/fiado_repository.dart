import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/cliente_fiado.dart';
import '../../domain/models/transaction.dart';
import '../datasources/database_helper.dart';

final fiadoRepoProvider = Provider((ref) => FiadoRepository());

class FiadoRepository {
  final dbHelper = DatabaseHelper.instance;

  // Obtener lista de clientes con deuda activa (HU04)
  Future<List<Map<String, dynamic>>> getDeudores() async {
    final db = await dbHelper.database;
    // Unimos clientes con sus fiados pendientes y sumamos el total
    return await db.rawQuery('''
      SELECT c.id, c.nombre, c.telefono, SUM(f.total) as deuda_total
      FROM clientes c
      JOIN fiados f ON c.id = f.cliente_id
      WHERE f.estado = 'pendiente'
      GROUP BY c.id
    ''');
  }

  // Pagar deuda (Abono) - Aquí aplicamos la decisión profesional
  Future<void> registrarAbono(String clienteId, double montoAbono, String nombreCliente) async {
    final db = await dbHelper.database;

    // Usamos transaction para asegurar que si algo falla, se deshace todo
    await db.transaction((txn) async {
      // 1. Buscamos los fiados pendientes del cliente ordenados por los más viejos
      final fiados = await txn.query('fiados', where: 'cliente_id = ? AND estado = ?', whereArgs: [clienteId, 'pendiente'], orderBy: 'fecha ASC');

      double montoRestante = montoAbono;

      for (var f in fiados) {
        if (montoRestante <= 0) break;

        double totalFiado = f['total'] as double;
        String idFiado = f['id'] as String;

        if (montoRestante >= totalFiado) {
          // Paga este fiado completo
          await txn.update('fiados', {'estado': 'pagado'}, where: 'id = ?', whereArgs: [idFiado]);
          montoRestante -= totalFiado;
        } else {
          // Paga una parte (actualizamos el total que debe de este fiado específico)
          await txn.update('fiados', {'total': totalFiado - montoRestante}, where: 'id = ?', whereArgs: [idFiado]);
          montoRestante = 0;
        }
      }

      // 2. LA MAGIA: Ingresamos el dinero a la caja diaria automáticamente
      final ingresoCaja = AppTransaction(
        id: const Uuid().v4(),
        tipo: TransactionType.ingreso,
        monto: montoAbono,
        fecha: DateTime.now(),
        categoria: 'Pago de Cartera', // Categoría especial
        descripcion: 'Abono de fiado - Cliente: $nombreCliente',
      );

      await txn.insert('transacciones', ingresoCaja.toMap());
    });
  }
  // --- AÑADIR A FIADO_REPOSITORY.DART ---

  // Obtener lista de todos los clientes registrados
  Future<List<Cliente>> getClientes() async {
    final db = await dbHelper.database;
    final maps = await db.query('clientes', orderBy: 'nombre ASC');
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  // Crear un nuevo cliente (HU03 - Escenario 2)
  Future<Cliente> crearCliente(String nombre, String telefono) async {
    final db = await dbHelper.database;
    final nuevoCliente = Cliente(id: const Uuid().v4(), nombre: nombre, telefono: telefono);
    await db.insert('clientes', nuevoCliente.toMap());
    return nuevoCliente;
  }

  // Registrar el nuevo fiado (Transacción compleja)
  Future<void> registrarNuevoFiado(String clienteId, List<Map<String, dynamic>> itemsDelCarrito) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      double totalFiado = 0;
      final fiadoId = const Uuid().v4();

      // 1. Calcular el total y descontar el stock de cada producto
      for (var item in itemsDelCarrito) {
        final productoId = item['productoId'];
        final cantidad = item['cantidad'] as int;
        final precio = item['precio'] as double;

        totalFiado += (precio * cantidad);

        // Guardar el detalle exacto (CP10)
        await txn.insert('detalle_fiados', {
          'id': const Uuid().v4(),
          'fiado_id': fiadoId,
          'producto_id': productoId,
          'cantidad': cantidad,
          'precio_unitario': precio,
        });

        // Descontar del inventario real
        await txn.rawUpdate(
            'UPDATE productos SET stock = stock - ? WHERE id = ?',
            [cantidad, productoId]
        );
      }

      // 2. Guardar la cabecera del Fiado
      await txn.insert('fiados', {
        'id': fiadoId,
        'cliente_id': clienteId,
        'fecha': DateTime.now().toIso8601String(),
        'total': totalFiado,
        'estado': 'pendiente',
      });
    });
  }
}