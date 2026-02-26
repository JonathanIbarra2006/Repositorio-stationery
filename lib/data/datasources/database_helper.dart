import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Patrón Singleton: Garantiza una única instancia de la base de datos
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inktrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Obtiene la ruta física segura en el dispositivo (Android/iOS/Windows)
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Abre la base de datos y llama a _createDB si es la primera vez
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Las sentencias SQL se ejecutan en orden

    // 1. Tabla de Productos (HU06, HU11, HU12)
    await db.execute('''
      CREATE TABLE productos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        precio REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    // 2. Tabla de Clientes para Fiados (HU03, HU04)
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT
      )
    ''');

    // 3. Tabla de Transacciones: Ingresos y Egresos (HU01, HU02)
    await db.execute('''
      CREATE TABLE transacciones (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL, -- 'ingreso' o 'gasto'
        monto REAL NOT NULL,
        fecha TEXT NOT NULL, -- Guardaremos en formato ISO-8601
        categoria TEXT,
        descripcion TEXT
      )
    ''');

    // 4. Tabla de Fiados (Deudas generales) (HU03, HU04)
    await db.execute('''
      CREATE TABLE fiados (
        id TEXT PRIMARY KEY,
        cliente_id TEXT NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        estado TEXT NOT NULL, -- 'pendiente' o 'pagado'
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabla Detalle de Fiados (Los productos exactos que se fiaron - CP10)
    await db.execute('''
      CREATE TABLE detalle_fiados (
        id TEXT PRIMARY KEY,
        fiado_id TEXT NOT NULL,
        producto_id TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        FOREIGN KEY (fiado_id) REFERENCES fiados (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE RESTRICT
      )
    ''');

    // 6. Tabla de Proveedores (HU05)
    await db.execute('''
      CREATE TABLE proveedores (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        contacto TEXT,
        empresa TEXT
      )
    ''');
  }

  // Método de utilidad para cerrar la BD
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}