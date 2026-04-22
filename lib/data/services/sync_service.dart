import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> uploadData() async {
    if (!await isOnline()) throw Exception('No hay conexión a internet');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final db = await _dbHelper.database;

    // Sync logic for each table
    await _uploadTable('productos', db, userId);
    await _uploadTable('proveedores', db, userId);
    await _uploadTable('clientes', db, userId);
    await _uploadTable('transacciones', db, userId);
    await _uploadTable('fiados', db, userId);
  }

  Future<void> _uploadTable(String tableName, dynamic db, String userId) async {
    final List<Map<String, dynamic>> localData = await db.query(tableName);
    if (localData.isEmpty) return;

    // Add user_id to each record before uploading
    final dataToUpload = localData.map((record) {
      final newRecord = Map<String, dynamic>.from(record);
      newRecord['user_id'] = userId;
      return newRecord;
    }).toList();

    await _supabase.from(tableName).upsert(dataToUpload);
  }

  Future<void> downloadData() async {
    if (!await isOnline()) throw Exception('No hay conexión a internet');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final db = await _dbHelper.database;

    // Sync logic for each table
    await _downloadTable('productos', db, userId);
    await _downloadTable('proveedores', db, userId);
    await _downloadTable('clientes', db, userId);
    await _downloadTable('transacciones', db, userId);
    await _downloadTable('fiados', db, userId);
  }

  Future<void> _downloadTable(String tableName, dynamic db, String userId) async {
    final remoteData = await _supabase.from(tableName).select().eq('user_id', userId);
    
    if (remoteData.isEmpty) return;

    await db.transaction((Transaction txn) async {
      for (var record in remoteData) {
        // Remove user_id before saving to local sqflite if not needed there
        final localRecord = Map<String, dynamic>.from(record as Map);
        localRecord.remove('user_id');
        
        await txn.insert(
          tableName,
          localRecord,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
