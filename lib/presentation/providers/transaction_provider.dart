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

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _repository.getTransactions();

      // Cálculo automático de totales
      double ingresos = 0;
      double gastos = 0;
      for (var t in transactions) {
        if (t.tipo == TransactionType.ingreso) ingresos += t.monto;
        if (t.tipo == TransactionType.gasto) gastos += t.monto;
      }

      state = AsyncValue.data(TransactionState(transactions, ingresos, gastos, ingresos - gastos));
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
}

final transactionsProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<TransactionState>>((ref) {
  return TransactionNotifier(ref.watch(transactionRepoProvider));
});