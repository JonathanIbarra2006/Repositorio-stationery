import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/database_helper.dart';
import 'package:uuid/uuid.dart';

// --- MODELO CLIENTE ---
class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final bool isActive;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.isActive = true,
  });
}

// --- PROVIDER DE CLIENTES ---
final clientesProvider =
    StateNotifierProvider<ClientesNotifier, AsyncValue<List<Cliente>>>((ref) {
  return ClientesNotifier();
});

class ClientesNotifier
    extends StateNotifier<AsyncValue<List<Cliente>>> {
  ClientesNotifier() : super(const AsyncValue.loading()) {
    loadClientes();
  }

  Future<void> loadClientes() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'clientes',
        orderBy: 'nombre ASC',
      );

      final clientes = result
          .map((row) => Cliente(
                id: row['id'] as String,
                nombre: row['nombre'] as String,
                telefono: row['telefono'] as String?,
                email: row['email'] as String?,
                isActive: row['is_active'] == null || row['is_active'] == 1,
              ))
          .toList();

      state = AsyncValue.data(clientes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- DESACTIVAR CLIENTE ---
  Future<String?> desactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
    await loadClientes();
    return null;
  }

  Future<void> reactivarCliente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('clientes', {'is_active': 1},
        where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  Future<void> eliminarClientePermanentemente(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    await loadClientes();
  }

  Future<void> registrarNuevoClienteDirecto(
      String nombre, String telefono, String? email) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('clientes', {
      'id': const Uuid().v4(),
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'is_active': 1
    });
    await loadClientes();
  }

  Future<void> editarCliente(
      String id, String nuevoNombre, String nuevoTelefono,
      String? nuevoEmail) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
        'clientes',
        {
          'nombre': nuevoNombre,
          'telefono': nuevoTelefono,
          'email': nuevoEmail
        },
        where: 'id = ?',
        whereArgs: [id]);
    await loadClientes();
  }
}