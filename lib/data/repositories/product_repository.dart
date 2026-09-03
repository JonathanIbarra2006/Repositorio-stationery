import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../domain/models/product.dart';
import '../datasources/database_helper.dart';

/// Excepción tipada para códigos de barra duplicados.
/// Permite capturarla con `is DuplicateBarcodeException` en vez de
/// comparar strings frágiles como `.contains('DUPLICADO')`.
class DuplicateBarcodeException implements Exception {
  final String barcode;
  const DuplicateBarcodeException(this.barcode);
  @override
  String toString() => 'DuplicateBarcodeException: El código "$barcode" ya existe.';
}

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
      // Primero revisamos si existe un producto ACTIVO con ese código
      final duplicadoActivo = await db.query(
        'productos',
        where: 'codigo_barras = ? AND is_active = 1',
        whereArgs: [product.codigoBarras],
      );
      if (duplicadoActivo.isNotEmpty) {
        throw DuplicateBarcodeException(product.codigoBarras!);
      }

      // Si no hay activo, verificamos si existe uno ARCHIVADO (informativo)
      final duplicadoArchivado = await db.query(
        'productos',
        where: 'codigo_barras = ? AND is_active = 0',
        whereArgs: [product.codigoBarras],
      );
      if (duplicadoArchivado.isNotEmpty) {
        throw Exception(
          'El código "${product.codigoBarras}" pertenece a un producto archivado. '
          'Reactívalo o usa un código diferente.',
        );
      }
    }

    await db.insert('productos', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> deactivateProduct(String id) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> reactivateProduct(String id) async {
    final db = await dbHelper.database;
    await db.update(
        'productos',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
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