import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'date_range_provider.dart';

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
  final DateTime? _startDate;
  final DateTime? _endDate;

  TransactionNotifier(this._repository, this._startDate, this._endDate) : super(const AsyncValue.loading());

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      // 1. Pedimos a la BD las transacciones filtradas
      final transacciones = await _repository.getTransactions(startDate: _startDate, endDate: _endDate);

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

  Future<String?> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      loadTransactions();
      return null;
    } catch (e) {
      return 'Error al eliminar la transacción.';
    }
  }
}

final transactionsProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<TransactionState>>((ref) {
  final repo = ref.watch(transactionRepoProvider);
  final dateRange = ref.watch(dateRangeProvider);
  
  final notifier = TransactionNotifier(repo, dateRange.range?.start, dateRange.range?.end);
  
  // Cargamos con el rango inicial
  // Usamos microtask para evitar errores de actualización durante el build
  Future.microtask(() => notifier.loadTransactions());
  
  return notifier;
});
