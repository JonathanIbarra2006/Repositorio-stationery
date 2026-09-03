import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import '../datasources/database_helper.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  // Insertar un nuevo ingreso o gasto (HU01 y HU02)
  Future<void> addTransaction(AppTransaction transaction) async {
    final db = await dbHelper.database;
    await db.insert('transacciones', transaction.toMap());
  }

  // Obtener todas las transacciones de un mes/día (Para el Dashboard y lista)
// Obtener transacciones (con filtro opcional de fechas)
  Future<List<AppTransaction>> getTransactions({DateTime? startDate, DateTime? endDate}) async {
    final db = await dbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'fecha >= ? AND fecha <= ?';
      // MAGIA SENIOR: Normalizamos para que incluya todo el día inicial y final completo
      final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      whereArgs = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
    }

    final maps = await db.query(
      'transacciones',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC', // Las más recientes primero
    );

    return List.generate(maps.length, (i) => AppTransaction.fromMap(maps[i]));
  }

  Future<void> registrarVentaContado(
    List<Map<String, dynamic>> carrito,
    double totalVenta, {
    String? descripcion,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      for (var item in carrito) {
        final cantidad = item['cantidad'] as int;
        final productoId = item['productoId'] as String;
        final nombre = item['nombre'] ?? 'Producto';

        // Verificar stock disponible antes de descontar (evita stock negativo)
        final stockResult = await txn.rawQuery(
          'SELECT stock FROM productos WHERE id = ?',
          [productoId],
        );
        if (stockResult.isEmpty) {
          throw Exception('Producto "$nombre" no encontrado en el inventario.');
        }
        final stockActual = stockResult.first['stock'] as int;
        if (stockActual < cantidad) {
          throw Exception(
            'Stock insuficiente para "$nombre": disponible $stockActual, solicitado $cantidad.',
          );
        }

        await txn.rawUpdate(
          'UPDATE productos SET stock = stock - ?, updated_at = ? WHERE id = ?',
          [cantidad, now, productoId],
        );
      }

      // Importante: asegúrate de tener import 'package:uuid/uuid.dart'; arriba en este archivo
      final ingreso = AppTransaction(
        id: const Uuid().v4(),
        tipo: TransactionType.ingreso,
        monto: totalVenta,
        fecha: DateTime.now(),
        categoria: 'Ventas de Contado',
        descripcion: descripcion ?? 'Venta rápida en mostrador',
      );
      await txn.insert('transacciones', ingreso.toMap());
    });
  }

  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'transacciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}