import '../../domain/models/product.dart';

class MockRepository {
  // Datos iniciales de prueba (Mock Data)
  final List<Product> _products = [
    Product(id: '1', nombre: 'Resma Carta', categoria: 'Papel', precio: 18000, stock: 50, proveedor: 'Proveedor A'),
    Product(id: '2', nombre: 'Tinta Negra Epson', categoria: 'Tintas', precio: 25000, stock: 12, proveedor: 'Proveedor B'),
    Product(id: '3', nombre: 'Lapicero Kilometrico', categoria: 'Útiles', precio: 1500, stock: 100, proveedor: 'Proveedor C'),
    Product(id: '4', nombre: 'Carpeta Plástica', categoria: 'Útiles', precio: 2000, stock: 30, proveedor: 'Proveedor D'),
  ];

  List<Product> getProducts() => _products;

  // Simular la venta (restar stock)
  void processSale(List<Map<String, dynamic>> itemsSold) {
    for (var item in itemsSold) {
      final productId = item['productId'];
      final quantity = item['quantity'] as int;

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final product = _products[index];
        final updatedProduct = Product(
          id: product.id,
          nombre: product.nombre,
          categoria: product.categoria,
          precio: product.precio,
          stock: product.stock - quantity,
          proveedor: product.proveedor,
        );
        _products[index] = updatedProduct;
      }
    }
  }
}