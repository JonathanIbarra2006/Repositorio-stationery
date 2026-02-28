import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cliente_fiado.dart';
import '../../data/repositories/fiado_repository.dart';

final clientesListProvider = FutureProvider<List<Cliente>>((ref) async {
  final repo = ref.watch(fiadoRepoProvider);
  return await repo.getClientes();
});