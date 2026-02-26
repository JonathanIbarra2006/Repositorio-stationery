class Product {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;

  Product({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
  });

  // Convertir de Objeto a Mapa (Para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
    };
  }

  // Convertir de Mapa a Objeto (Para leer de SQLite)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      precio: map['precio'],
      stock: map['stock'],
    );
  }
}