import 'package:sqflite/sqflite.dart';
import '../../domain/models/product.dart';
import '../datasources/database_helper.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  // 1. Listar productos (con filtro de búsqueda)
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

  // 2. Agregar producto (Valida duplicados)
  Future<void> addProduct(Product product) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'productos',
      where: 'LOWER(nombre) = ?',
      whereArgs: [product.nombre.toLowerCase()],
    );

    if (result.isNotEmpty) {
      throw Exception('DUPLICADO');
    }

    await db.insert('productos', product.toMap());
  }

  // 3. Eliminar producto (Valida que no esté en uso)
  Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    try {
      await db.delete('productos', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY')) {
        throw Exception('EN_USO');
      }
      rethrow;
    }
  }

  // 4. Editar/Actualizar producto (La función nueva de la Versión 2.0)
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