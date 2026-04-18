class Product {
  final String id;
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final String? codigoBarras;
  final String proveedor;
  final int stockMinimo; // Nivel mínimo antes de alerta
  final bool isActive;

  Product({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.codigoBarras,
    required this.proveedor,
    this.stockMinimo = 5,
    this.isActive = true,
  });

  Product copyWith({
    String? id,
    String? nombre,
    String? categoria,
    double? precio,
    int? stock,
    String? codigoBarras,
    String? proveedor,
    int? stockMinimo,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      proveedor: proveedor ?? this.proveedor,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'codigo_barras': codigoBarras,
      'proveedor': proveedor,
      'stock_minimo': stockMinimo,
      'is_active': isActive ? 1 : 0,
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
      proveedor: map['proveedor'] ?? 'Sin Proveedor',
      stockMinimo: map['stock_minimo'] ?? 5,
      isActive: map['is_active'] == null || map['is_active'] == 1,
    );
  }
}