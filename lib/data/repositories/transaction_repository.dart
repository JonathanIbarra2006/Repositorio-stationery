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
      // MAGIA SENIOR: Le sumamos 23h 59m 59s al día final para incluir todas las ventas de ese último día
      final endOfDay = endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      whereArgs = [startDate.toIso8601String(), endOfDay.toIso8601String()];
    }

    final maps = await db.query(
      'transacciones',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC', // Las más recientes primero
    );

    return List.generate(maps.length, (i) => AppTransaction.fromMap(maps[i]));
  }

  Future<void> registrarVentaContado(List<Map<String, dynamic>> carrito, double totalVenta) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      for (var item in carrito) {
        await txn.rawUpdate(
            'UPDATE productos SET stock = stock - ? WHERE id = ?',
            [item['cantidad'], item['productoId']]
        );
      }
      // Importante: asegúrate de tener import 'package:uuid/uuid.dart'; arriba en este archivo
      final ingreso = AppTransaction(
        id: const Uuid().v4(),
        tipo: TransactionType.ingreso,
        monto: totalVenta,
        fecha: DateTime.now(),
        categoria: 'Ventas de Contado',
        descripcion: 'Venta rápida en mostrador',
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