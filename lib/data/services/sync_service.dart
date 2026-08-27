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

const _syncTables = [
  'productos',
  'proveedores',
  'clientes',
  'transacciones',
  'fiados',
  'abonos_fiados',
];

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
        warnings.add('${_getFriendlyTableName(table)}: ${e.message}');
        counts[table] = 0;
      } catch (e) {
        warnings.add('${_getFriendlyTableName(table)}: ${_mapSupabaseError(e)}');
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

    // Protección crítica: si no hay datos locales, salimos ANTES de ejecutar
    // cualquier lógica de eliminación remota. Sin esto, una base vacía (p.ej.
    // dispositivo nuevo) haría que se interpretara que TODOS los registros en
    // Supabase deben borrarse, eliminando el respaldo completo del negocio.
    if (localData.isEmpty) return 0;

    // 1. Sincronización de Eliminaciones
    // Obtenemos los IDs remotos en Supabase y borramos los que ya no existen
    // localmente. Esto solo se ejecuta si hay datos locales (guarda arriba).
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
        warnings.add('${_getFriendlyTableName(table)}: ${e.message}');
        counts[table] = 0;
      } catch (e) {
        warnings.add('${_getFriendlyTableName(table)}: ${_mapSupabaseError(e)}');
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
          // No existe localmente → Insertar como nuevo
          await txn.insert(tableName, localRecord);
        } else {
          // Existe localmente → Estrategia "última escritura gana" (last-write-wins)
          // usando updated_at. Quien tenga el timestamp más reciente prevalece.
          // Si el local no tiene updated_at (registros previos a v10), el remoto gana.
          final localRow = existing.first;
          final remoteUpdatedAt = localRecord['updated_at'] as String?;
          final localUpdatedAt = localRow['updated_at'] as String?;

          final bool remoteIsNewer;
          if (remoteUpdatedAt == null) {
            // Remoto no tiene timestamp → no sobreescribir
            remoteIsNewer = false;
          } else if (localUpdatedAt == null) {
            // Local no tiene timestamp (registro antiguo) → el remoto gana
            remoteIsNewer = true;
          } else {
            // Ambos tienen timestamp → comparar
            remoteIsNewer = remoteUpdatedAt.compareTo(localUpdatedAt) > 0;
          }

          if (remoteIsNewer) {
            // El remoto es más reciente: sobreescribir todos los campos locales
            // con los valores remotos (excepto 'id' que ya es el mismo).
            final updateMap = Map<String, dynamic>.from(localRecord)..remove('id');
            if (updateMap.isNotEmpty) {
              await txn.update(
                tableName,
                updateMap,
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          }
          // Si el local es más reciente (o igual), no se toca nada.
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

  String _getFriendlyTableName(String table) {
    switch (table) {
      case 'productos':
        return 'Productos';
      case 'proveedores':
        return 'Proveedores';
      case 'clientes':
        return 'Clientes';
      case 'transacciones':
        return 'Transacciones';
      case 'fiados':
        return 'Clientes fiados';
      case 'abonos_fiados':
        return 'Abonos a deudas';
      default:
        return table;
    }
  }

  /// Traduce errores de Supabase/red a mensajes amigables en español.
  String _mapSupabaseError(Object e) {
    final raw = e.toString();
    final msg = raw.toLowerCase();

    // Tabla no encontrada (PGRST205 / Could not find the table)
    if (msg.contains('pgrst205') ||
        msg.contains('could not find the table') ||
        (msg.contains('schema cache') && msg.contains('table'))) {
      return 'La tabla o sección no está disponible en la base de datos de la nube. Contacta al administrador.';
    }

    // Columna no encontrada en Supabase (PGRST204)
    if (msg.contains('pgrst204') ||
        (msg.contains('could not find') && msg.contains('column'))) {
      final match = RegExp(r"find the '(\w+)' column").firstMatch(raw);
      final col = match?.group(1) ?? 'desconocida';
      return 'La columna "$col" no está configurada en el servidor. Contacta al administrador.';
    }

    // Columna user_id faltante
    if (msg.contains('column') && msg.contains('user_id')) {
      return 'Error de configuración de usuario en la base de datos. Contacta al administrador.';
    }

    // RLS / permisos
    if (msg.contains('row-level security') ||
        msg.contains('violates row-level') ||
        msg.contains('permission denied') ||
        msg.contains('insufficient_privilege')) {
      return 'No tienes permisos de escritura para guardar datos en la nube. Contacta al administrador.';
    }

    // Tabla inexistente
    if (msg.contains('relation') && msg.contains('does not exist')) {
      return 'La tabla no existe en la base de datos de la nube. Contacta al administrador.';
    }

    // Sesión expirada
    if (msg.contains('jwt') ||
        msg.contains('expired') ||
        msg.contains('invalid token')) {
      return 'Tu sesión de sincronización ha vencido. Por favor, vuelve a iniciar sesión.';
    }

    // Problemas de red
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection refused')) {
      return 'Sin conexión con el servidor. Revisa tu conexión a internet e inténtalo de nuevo.';
    }

    if (msg.contains('timeout')) {
      return 'Se agotó el tiempo de espera del servidor. Inténtalo de nuevo.';
    }

    // Error genérico: devuelve el mensaje real sin prefijos de excepción, limpio
    return raw
        .replaceAll('Exception: ', '')
        .replaceAll('SyncException: ', '')
        .replaceAll('PostgrestException: ', '')
        .trim();
  }
}
