import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Resultado tipado de sincronización
// ──────────────────────────────────────────────────────────────────────────────

class SyncResult {
  final Map<String, int> tablesCounts; // tabla → registros sincronizados
  final List<String> warnings;         // advertencias no fatales

  const SyncResult({required this.tablesCounts, required this.warnings});

  int get totalRecords => tablesCounts.values.fold(0, (a, b) => a + b);
}

// ──────────────────────────────────────────────────────────────────────────────
// Excepción de sincronización
// ──────────────────────────────────────────────────────────────────────────────

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => message;
}

// ──────────────────────────────────────────────────────────────────────────────
// Tablas a sincronizar (en orden: sin dependencias primero)
// ──────────────────────────────────────────────────────────────────────────────

const _syncTables = ['productos', 'proveedores', 'clientes', 'transacciones'];

// ──────────────────────────────────────────────────────────────────────────────
// SyncService
// ──────────────────────────────────────────────────────────────────────────────

class SyncService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  // ── Conectividad ────────────────────────────────────────────────────────────

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ── Columnas locales de SQLite ───────────────────────────────────────────────
  // Lee el PRAGMA de SQLite para saber exactamente qué columnas existen
  // en la tabla local. Esto sirve tanto para upload (excluir columnas que
  // Supabase no conoce) como para download (excluir columnas que no existen
  // localmente).

  Future<Set<String>> _getLocalColumns(Database db, String tableName) async {
    final info = await db.rawQuery('PRAGMA table_info($tableName)');
    return info.map((row) => row['name'] as String).toSet();
  }

  // ── Subir datos ─────────────────────────────────────────────────────────────

  Future<SyncResult> uploadData({required String password}) async {
    _requireOnline(await isOnline());

    final userId = _requireAuth();
    final userEmail = _supabase.auth.currentUser?.email;

    if (userEmail == null) {
      throw const SyncException('No se pudo verificar tu sesión actual.');
    }

    try {
      await _supabase.auth.signInWithPassword(email: userEmail, password: password);
    } catch (e) {
      throw const SyncException('Contraseña incorrecta. No se autorizó la subida de datos.');
    }

    final db = await _dbHelper.database;

    final counts = <String, int>{};
    final warnings = <String>[];

    for (final table in _syncTables) {
      try {
        final n = await _uploadTable(table, db, userId);
        counts[table] = n;
      } on SyncException catch (e) {
        warnings.add('$table: ${e.message}');
        counts[table] = 0;
      } catch (e) {
        warnings.add('$table: ${_mapSupabaseError(e)}');
        counts[table] = 0;
      }
    }

    return SyncResult(tablesCounts: counts, warnings: warnings);
  }

  /// Sube una tabla con auto-reintento inteligente.
  ///
  /// Si Supabase rechaza una columna (PGRST204 — columna no existe en el
  /// esquema remoto), la elimina del payload y reintenta automáticamente.
  /// Esto permite sincronizar aunque el esquema local tenga columnas extra
  /// que aún no se han agregado en Supabase (p.ej. `email` en `clientes`).
  Future<int> _uploadTable(
    String tableName,
    Database db,
    String userId,
  ) async {
    final List<Map<String, dynamic>> localData = await db.query(tableName);

    // 1. Sincronización de Eliminaciones
    // Obtenemos los IDs remotos en Supabase
    try {
      final remoteRecords = await _supabase.from(tableName).select('id').eq('user_id', userId);
      final remoteIds = remoteRecords.map((r) => r['id'].toString()).toSet();
      final localIds = localData.map((r) => r['id'].toString()).toSet();

      final idsToDelete = remoteIds.difference(localIds);

      if (idsToDelete.isNotEmpty) {
        // Eliminamos de Supabase los que ya no están localmente
        await _supabase.from(tableName).delete().inFilter('id', idsToDelete.toList());
      }
    } catch (e) {
      // Ignoramos errores de eliminación para no frenar el Upsert si la tabla aún no existe, etc.
    }

    if (localData.isEmpty) return 0;

    // Columnas que se excluirán del payload por incompatibilidad con Supabase.
    // Se populan dinámicamente si Supabase responde con PGRST204.
    final excludedCols = <String>{};

    const maxAttempts = 8; // Límite de reintentos para evitar bucles infinitos
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;

      // Construye el payload filtrando columnas excluidas
      final payload = localData.map((record) {
        final row = Map<String, dynamic>.from(record);
        row['user_id'] = userId;
        for (final col in excludedCols) {
          row.remove(col);
        }
        return row;
      }).toList();

      try {
        // onConflict: 'id' → hace upsert usando la PK como columna de conflicto
        await _supabase.from(tableName).upsert(payload, onConflict: 'id');
        return payload.length;
      } catch (e) {
        final raw = e.toString();

        // ── PGRST204: columna no encontrada en el esquema de Supabase ──────
        // Mensaje típico:
        //   "Could not find the 'email' column of 'clientes' in the schema cache"
        if (raw.contains('PGRST204') ||
            raw.contains('Could not find') ||
            raw.contains('schema cache')) {
          final match =
              RegExp(r"find the '(\w+)' column").firstMatch(raw) ??
              RegExp(r"column[^']*'(\w+)'").firstMatch(raw);

          if (match != null) {
            final badCol = match.group(1)!;
            // Nunca eliminar 'id' ni 'user_id' → son esenciales
            if (badCol != 'id' && badCol != 'user_id') {
              excludedCols.add(badCol);
              continue; // Reintento con la columna excluida
            }
          }
        }

        // ── Cualquier otro error → propagar como SyncException ────────────
        throw SyncException(_mapSupabaseError(e));
      }
    }

    throw const SyncException(
      'No se pudo completar la subida tras múltiples intentos.',
    );
  }

  // ── Descargar datos ─────────────────────────────────────────────────────────

  Future<SyncResult> downloadData() async {
    _requireOnline(await isOnline());

    final userId = _requireAuth();
    final db = await _dbHelper.database;

    final counts = <String, int>{};
    final warnings = <String>[];

    for (final table in _syncTables) {
      try {
        final n = await _downloadTable(table, db, userId);
        counts[table] = n;
      } on SyncException catch (e) {
        warnings.add('$table: ${e.message}');
        counts[table] = 0;
      } catch (e) {
        warnings.add('$table: ${_mapSupabaseError(e)}');
        counts[table] = 0;
      }
    }

    return SyncResult(tablesCounts: counts, warnings: warnings);
  }

  /// Descarga una tabla y sólo guarda localmente las columnas que
  /// ya existen en el esquema SQLite (evita errores por columnas extra
  /// que Supabase pueda tener y que SQLite no conozca).
  Future<int> _downloadTable(
    String tableName,
    Database db,
    String userId,
  ) async {
    // Columnas válidas en SQLite local para esta tabla
    final localCols = await _getLocalColumns(db, tableName);

    List<dynamic> remoteData;
    try {
      remoteData = await _supabase
          .from(tableName)
          .select()
          .eq('user_id', userId);
    } catch (e) {
      throw SyncException(_mapSupabaseError(e));
    }

    if (remoteData.isEmpty) return 0;

    await db.transaction((Transaction txn) async {
      for (final record in remoteData) {
        final raw = Map<String, dynamic>.from(record as Map);

        // Quita user_id (columna de Supabase, no existe localmente)
        raw.remove('user_id');

        // Filtra sólo columnas que existen en el SQLite local
        final localRecord = Map<String, dynamic>.fromEntries(
          raw.entries.where((e) => localCols.contains(e.key)),
        );

        if (localRecord.isEmpty) continue;

        final id = localRecord['id'];
        if (id == null) continue;

        final existing = await txn.query(
          tableName,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (existing.isEmpty) {
          // No existe localmente: Insertar nuevo
          await txn.insert(
            tableName,
            localRecord,
          );
        } else {
          // Existe localmente: Combinación inteligente (Merge)
          final localRow = existing.first;
          final updateMap = <String, dynamic>{};

          for (final key in localRecord.keys) {
            final remoteVal = localRecord[key];
            final localVal = localRow[key];

            // Solo actualizamos si el local está vacío y el remoto tiene datos
            if ((localVal == null || localVal == '') && (remoteVal != null && remoteVal != '')) {
              updateMap[key] = remoteVal;
            }
          }

          if (updateMap.isNotEmpty) {
            await txn.update(
              tableName,
              updateMap,
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }
    });

    return remoteData.length;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _requireOnline(bool online) {
    if (!online) {
      throw const SyncException(
        'Sin conexión a internet. Verifica tu red e intenta de nuevo.',
      );
    }
  }

  String _requireAuth() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const SyncException(
        'Debes iniciar sesión para sincronizar los datos.',
      );
    }
    return userId;
  }

  /// Traduce errores de Supabase/red a mensajes amigables en español.
  String _mapSupabaseError(Object e) {
    final raw = e.toString();
    final msg = raw.toLowerCase();

    // Columna no encontrada en Supabase (PGRST204)
    if (msg.contains('pgrst204') ||
        (msg.contains('could not find') && msg.contains('column'))) {
      final match = RegExp(r"find the '(\w+)' column").firstMatch(raw);
      final col = match?.group(1) ?? 'desconocida';
      return 'La columna "$col" no existe en Supabase. Agrégala en el dashboard o es una columna solo local.';
    }

    // Columna user_id faltante
    if (msg.contains('column') && msg.contains('user_id')) {
      return 'La tabla en Supabase no tiene la columna user_id. Agrégala en el dashboard.';
    }

    // RLS / permisos
    if (msg.contains('row-level security') ||
        msg.contains('violates row-level') ||
        msg.contains('permission denied') ||
        msg.contains('insufficient_privilege')) {
      return 'Sin permisos de escritura en Supabase. En el dashboard ve a Authentication → Policies y agrega una política INSERT/UPDATE para usuarios autenticados.';
    }

    // Tabla inexistente
    if (msg.contains('relation') && msg.contains('does not exist')) {
      return 'La tabla no existe en Supabase. Créala primero en el dashboard de Supabase.';
    }

    // Sesión expirada
    if (msg.contains('jwt') ||
        msg.contains('expired') ||
        msg.contains('invalid token')) {
      return 'Sesión expirada. Cierra sesión e inicia de nuevo.';
    }

    // Problemas de red
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection refused')) {
      return 'Error de red. Verifica tu conexión a internet.';
    }

    if (msg.contains('timeout')) {
      return 'Tiempo de espera agotado. Intenta de nuevo.';
    }

    // Error genérico: devuelve el mensaje real sin prefijos de excepción
    return raw
        .replaceAll('Exception: ', '')
        .replaceAll('SyncException: ', '');
  }
}
