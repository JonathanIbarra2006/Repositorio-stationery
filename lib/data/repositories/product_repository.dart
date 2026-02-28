import 'package:sqflite/sqflite.dart';
import '../../domain/models/product.dart';
import '../datasources/database_helper.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Product>> getProducts({String? query}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'productos',
        where: 'nombre LIKE ? OR codigo_barras LIKE ?', // Buscamos por nombre O código
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nombre ASC',
      );
    } else {
      maps = await db.query('productos', orderBy: 'nombre ASC');
    }

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

  Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
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