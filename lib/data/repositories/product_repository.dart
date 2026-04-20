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
        where: '(nombre LIKE ? OR codigo_barras LIKE ?) AND is_active = 1', // Buscamos por nombre O código, y solo activos
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nombre ASC',
      );
    } else {
      maps = await db.query('productos', where: 'is_active = 1', orderBy: 'nombre ASC');
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


  Future<void> deactivateProduct(String id) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        {'is_active': 0},
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