import 'package:sqflite/sqflite.dart';
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
  Future<List<AppTransaction>> getTransactions() async {
    final db = await dbHelper.database;
    // Las ordenamos de la más reciente a la más antigua
    final maps = await db.query('transacciones', orderBy: 'fecha DESC');
    return List.generate(maps.length, (i) => AppTransaction.fromMap(maps[i]));
  }
}