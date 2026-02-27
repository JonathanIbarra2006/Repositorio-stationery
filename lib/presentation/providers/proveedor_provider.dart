import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/proveedor.dart';
import '../../data/repositories/proveedor_repository.dart';

final proveedorRepoProvider = Provider((ref) => ProveedorRepository());

class ProveedorNotifier extends StateNotifier<AsyncValue<List<Proveedor>>> {
  final ProveedorRepository _repository;

  ProveedorNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProveedores();
  }

  Future<void> loadProveedores() async {
    state = const AsyncValue.loading();
    try {
      final proveedores = await _repository.getProveedores();
      state = AsyncValue.data(proveedores);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addProveedor(Proveedor proveedor) async {
    await _repository.addProveedor(proveedor);
    loadProveedores();
  }

  Future<void> updateProveedor(Proveedor proveedor) async {
    await _repository.updateProveedor(proveedor);
    loadProveedores();
  }

  Future<void> deleteProveedor(String id) async {
    await _repository.deleteProveedor(id);
    loadProveedores();
  }
}

final proveedoresProvider = StateNotifierProvider<ProveedorNotifier, AsyncValue<List<Proveedor>>>((ref) {
  return ProveedorNotifier(ref.watch(proveedorRepoProvider));
});