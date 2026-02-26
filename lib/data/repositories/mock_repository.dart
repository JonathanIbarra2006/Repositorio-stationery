import 'package:uuid/uuid.dart';
import '../../domain/models/product.dart';

class MockRepository {
  // Datos iniciales de prueba (Mock Data)
  final List<Product> _products = [
    Product(id: '1', name: 'Resma Carta', category: 'Papel', price: 18000, stock: 50),
    Product(id: '2', name: 'Tinta Negra Epson', category: 'Tintas', price: 25000, stock: 12),
    Product(id: '3', name: 'Lapicero Kilometrico', category: 'Útiles', price: 1500, stock: 100),
    Product(id: '4', name: 'Carpeta Plástica', category: 'Útiles', price: 2000, stock: 30),
  ];

  List<Product> getProducts() => _products;

  // Simular la venta (restar stock)
  void processSale(List<Map<String, dynamic>> itemsSold) {
    for (var item in itemsSold) {
      final productId = item['productId'];
      final quantity = item['quantity'] as int;

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final currentStock = _products[index].stock;
        // Actualizamos el stock en la lista
        _products[index] = _products[index].copyWith(stock: currentStock - quantity);
      }
    }
  }
}