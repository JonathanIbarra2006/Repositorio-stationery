import 'package:sqflite/sqflite.dart';
import '../../domain/models/product.dart';
import '../datasources/database_helper.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Product>> getProducts({String? query, bool includeInactive = false}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    String whereClause = includeInactive ? '1=1' : 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND (nombre LIKE ? OR codigo_barras LIKE ?)';
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    maps = await db.query(
      'productos',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'nombre ASC',
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<void> addProduct(Product product) async {
    final db = await dbHelper.database;

    // Validación: No permitir códigos de barra duplicados si existen
    if (product.codigoBarras != null && product.codigoBarras!.isNotEmpty) {
      final duplicado = await db.query('productos', where: 'codigo_barras = ?', whereArgs: [product.codigoBarras]);
      if (duplicado.isNotEmpty) throw Exception('Código de barras ya existe');
    }

    await db.insert('productos', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> deactivateProduct(String id) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> reactivateProduct(String id) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> deleteProductPermanently(String id) async {
    final db = await dbHelper.database;
    await db.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> updateProduct(Product product) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id]
    );
  }
}