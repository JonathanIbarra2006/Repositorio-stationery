import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepoProvider = Provider((ref) => TransactionRepository());

class TransactionState {
  final List<AppTransaction> transactions;
  final double totalIngresos;
  final double totalGastos;
  final double balance;

  TransactionState(this.transactions, this.totalIngresos, this.totalGastos, this.balance);
}

class TransactionNotifier extends StateNotifier<AsyncValue<TransactionState>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({DateTime? startDate, DateTime? endDate}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Pedimos a la BD las transacciones filtradas
      final transacciones = await _repository.getTransactions(startDate: startDate, endDate: endDate);

      // 2. Recalculamos el balance SOLO de esas fechas
      double ingresos = 0;
      double gastos = 0;

      for (var t in transacciones) {
        if (t.tipo == TransactionType.ingreso) ingresos += t.monto;
        if (t.tipo == TransactionType.gasto) gastos += t.monto;
      }

      // 3. Actualizamos la pantalla
      state = AsyncValue.data(TransactionState(
        transacciones,
        ingresos,
        gastos,
        ingresos - gastos,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> addTransaction(AppTransaction transaction) async {
    try {
      await _repository.addTransaction(transaction);
      loadTransactions();
      return null;
    } catch (e) {
      return 'Error al guardar la transacción.';
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      loadTransactions();
    } catch (e) {
      // Manejar el error apropiadamente
    }
  }
}

final transactionsProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<TransactionState>>((ref) {
  return TransactionNotifier(ref.watch(transactionRepoProvider));
});
