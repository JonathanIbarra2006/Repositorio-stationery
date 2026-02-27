import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/mock_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/cart_item.dart';

// 1. Instancia del repositorio
final repositoryProvider = Provider((ref) => MockRepository());

// 2. Provider de Productos (Inventario)
class InventoryNotifier extends StateNotifier<List<Product>> {
  final MockRepository _repo;

  InventoryNotifier(this._repo) : super([]) {
    state = _repo.getProducts(); // Cargar productos al iniciar
  }

  void refresh() {
    state = [..._repo.getProducts()]; // Forzar actualización visual
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<Product>>((ref) {
  return InventoryNotifier(ref.watch(repositoryProvider));
});

// 3. Provider del Carrito de Compras (Ventas)
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    // Disminuir stock del producto
    product.stock--;

    // Si ya existe, sumamos 1
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      final existingItem = state[index];
      state = [
        ...state.sublist(0, index),
        CartItem(product: existingItem.product, quantity: existingItem.quantity + 1),
        ...state.sublist(index + 1),
      ];
    } else {
      // Si no existe, lo agregamos
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});