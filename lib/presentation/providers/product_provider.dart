import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

// Usamos StateNotifier para manejar el estado de la lista y el buscador
class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({String? query}) async {
    state = const AsyncValue.loading();
    try {
      final products = await _repository.getProducts(query: query);
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> addProduct(Product product) async {
    try {
      await _repository.addProduct(product);
      loadProducts(); // Recarga la lista tras agregar
      return null; // Null significa "Sin errores"
    } catch (e) {
      if (e.toString().contains('DUPLICADO')) {
        return 'El producto ya está registrado en el inventario.';
      }
      return 'Error al guardar el producto.';
    }
  }


  Future<String?> deactivateProduct(String id) async {
    try {
      await _repository.deactivateProduct(id);
      loadProducts();
      return null;
    } catch (e) {
      return 'Error al desactivar el producto.';
    }
  }
  Future<String?> editProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      loadProducts(); // Recargar lista
      return null;
    } catch (e) {
      return 'Error al actualizar el producto.';
    }
  }
}

final productsProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier(ref.watch(productRepositoryProvider));
});