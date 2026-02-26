import 'package:sqflite/sqflite.dart';
import '../../domain/models/product.dart';
import '../datasources/database_helper.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  // Listar productos (con filtro de búsqueda opcional - HU12)
  Future<List<Product>> getProducts({String? query}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'productos',
        where: 'nombre LIKE ? OR categoria LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nombre ASC',
      );
    } else {
      maps = await db.query('productos', orderBy: 'nombre ASC');
    }

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Agregar producto (HU11 - Validar duplicados)
  Future<void> addProduct(Product product) async {
    final db = await dbHelper.database;

    // Verificar si ya existe un producto con el mismo nombre exacto
    final result = await db.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: [product.nombre.toLowerCase()],
    );

    if (result.isNotEmpty) {
      throw Exception('DUPLICADO'); // Dispara la advertencia de la HU11 Escenario 3
    }

    await db.insert('productos', product.toMap());
  }

  // Eliminar producto (HU11 - Validar uso previo)
  Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    try {
      await db.delete('productos', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      // Como en el Sprint 1 pusimos 'ON DELETE RESTRICT', SQLite lanzará un error si está en uso.
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        throw Exception('EN_USO'); // Dispara advertencia HU11 Escenario 4
      }
      rethrow;
    }
  }
}