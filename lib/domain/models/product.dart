class Product {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String? codigoBarras; // Nuevo: Opcional
  final String proveedor;     // Nuevo: Obligatorio

  Product({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.codigoBarras,
    required this.proveedor,
  });

  Product copyWith({
    String? id,
    String? nombre,
    String? categoria,
    double? precio,
    int? stock,
    String? codigoBarras,
    String? proveedor,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      proveedor: proveedor ?? this.proveedor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'codigo_barras': codigoBarras, // Se guarda en la BD
      'proveedor': proveedor,        // Se guarda en la BD
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      precio: map['precio'],
      stock: map['stock'],
      codigoBarras: map['codigo_barras'],
      proveedor: map['proveedor'] ?? 'Sin Proveedor', // Protección por si es null
    );
  }
}