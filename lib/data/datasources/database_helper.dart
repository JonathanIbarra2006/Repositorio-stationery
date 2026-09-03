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
      version: 11,
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
        is_active INTEGER DEFAULT 1,
        updated_at TEXT
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
        cliente_id TEXT,
        updated_at TEXT
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
        is_active INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    // 4. Clientes
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        cedula TEXT,
        telefono TEXT,
        email TEXT,
        is_active INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_clientes_cedula 
      ON clientes(cedula) 
      WHERE cedula IS NOT NULL AND cedula != ''
    ''');

    // 5. Fiados
    await db.execute('''
      CREATE TABLE fiados (
        id TEXT PRIMARY KEY,
        cliente_id TEXT NOT NULL,
        total REAL NOT NULL,
        monto_pagado REAL DEFAULT 0,
        fecha TEXT NOT NULL,
        estado TEXT NOT NULL,
        productos TEXT,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    // 6. Abonos de Fiados
    await db.execute('''
      CREATE TABLE abonos_fiados (
        id TEXT PRIMARY KEY,
        fiado_id TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        nota TEXT,
        updated_at TEXT,
        FOREIGN KEY (fiado_id) REFERENCES fiados (id)
      )
    ''');
  }

  /// Migraciones de versión
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
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN email TEXT',
      );
    }
    if (oldVersion < 8) {
      // Nueva tabla para abonos a fiados
      await db.execute('''
        CREATE TABLE IF NOT EXISTS abonos_fiados (
          id TEXT PRIMARY KEY,
          fiado_id TEXT NOT NULL,
          monto REAL NOT NULL,
          fecha TEXT NOT NULL,
          nota TEXT,
          FOREIGN KEY (fiado_id) REFERENCES fiados (id)
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN cedula TEXT',
      );
    }
    if (oldVersion < 10) {
      // Agrega updated_at a todas las tablas para sincronización multi-dispositivo
      // "última escritura gana" (last-write-wins).
      for (final table in [
        'productos',
        'transacciones',
        'proveedores',
        'clientes',
        'fiados',
        'abonos_fiados',
      ]) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN updated_at TEXT',
        );
      }
    }
    if (oldVersion < 11) {
      // Protegemos con try/catch: si ya existen cédulas duplicadas de versiones
      // anteriores, el CREATE UNIQUE INDEX fallaría. En ese caso registramos el
      // error sin tumbar la apertura de la BD; la validación por código queda
      // activa en la capa de aplicación (fiado_provider.dart).
      try {
        await db.execute('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_clientes_cedula 
          ON clientes(cedula) 
          WHERE cedula IS NOT NULL AND cedula != ''
        ''');
      } catch (e) {
        // ignore: avoid_print
        print('[DB migración v11] No se pudo crear índice único de cédula: $e');
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}