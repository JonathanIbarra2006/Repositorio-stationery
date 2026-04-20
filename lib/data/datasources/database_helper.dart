import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('klip_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Productos
    await db.execute('''
      CREATE TABLE productos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        precio REAL NOT NULL,
        stock INTEGER NOT NULL,
        codigo_barras TEXT,
        proveedor TEXT NOT NULL,
        stock_minimo INTEGER DEFAULT 5,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 2. Transacciones (Caja)
    await db.execute('''
      CREATE TABLE transacciones (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        categoria TEXT NOT NULL,
        cliente_id TEXT
      )
    ''');

    // 3. Proveedores
    await db.execute('''
      CREATE TABLE proveedores (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        contacto TEXT NOT NULL,
        empresa TEXT NOT NULL,
        dias_visita TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 4. Clientes
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 5. Fiados (CON CAMPO NUEVO: MONTO_PAGADO)
    await db.execute('''
      CREATE TABLE fiados (
        id TEXT PRIMARY KEY,
        cliente_id TEXT NOT NULL,
        total REAL NOT NULL,
        monto_pagado REAL DEFAULT 0,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        productos TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');
  }

  /// Migración de versión 1 → 2 y 2 → 3
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN stock_minimo INTEGER DEFAULT 5',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN is_active INTEGER DEFAULT 1',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE proveedores ADD COLUMN dias_visita TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE proveedores ADD COLUMN is_active INTEGER DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN is_active INTEGER DEFAULT 1',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE transacciones ADD COLUMN cliente_id TEXT',
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}