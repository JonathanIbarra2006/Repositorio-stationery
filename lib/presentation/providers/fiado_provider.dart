import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fiado_repository.dart';

final fiadoRepoProvider = Provider((ref) => FiadoRepository());

// Proveedor para listar los deudores
final deudoresProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(fiadoRepoProvider);
  return await repo.getDeudores();
});