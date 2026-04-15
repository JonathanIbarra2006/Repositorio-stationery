import '../../domain/models/proveedor.dart';
import '../datasources/database_helper.dart';

class ProveedorRepository {
  final dbHelper = DatabaseHelper.instance;

  // Gets all proveedores
  Future<List<Proveedor>> getProveedores() async {
    final db = await dbHelper.database;
    final maps = await db.query('proveedores', orderBy: 'empresa ASC');
    return List.generate(maps.length, (i) => Proveedor.fromMap(maps[i]));
  }

  Future<void> addProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    await db.insert('proveedores', proveedor.toMap());
  }

  Future<void> updateProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    await db.update('proveedores', proveedor.toMap(), where: 'id = ?', whereArgs: [proveedor.id]);
  }

  Future<void> deleteProveedor(String id) async {
    final db = await dbHelper.database;
    await db.delete('proveedores', where: 'id = ?', whereArgs: [id]);
  }
}