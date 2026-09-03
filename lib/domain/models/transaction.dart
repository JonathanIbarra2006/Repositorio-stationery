enum TransactionType { ingreso, gasto }

class AppTransaction {
  final String id;
  final TransactionType tipo;
  final double monto;
  final DateTime fecha;
  final String categoria; // Obligatorio (NOT NULL en SQLite)
  final String descripcion;
  final String? clienteId; // Opcional: para saber qué cliente realizó la compra
  /// Fix #7: JSON del carrito de venta. Permite reponer stock si se elimina la transacción.
  /// Formato: '[{"productoId":"...","nombre":"...","cantidad":2,"precio":1000}]'
  final String? productosJson;

  AppTransaction({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    this.clienteId,
    this.productosJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo == TransactionType.ingreso ? 'ingreso' : 'gasto',
      'monto': monto,
      'fecha': fecha.toIso8601String(), // SQLite prefiere las fechas en texto ISO
      'categoria': categoria,
      'descripcion': descripcion,
      'cliente_id': clienteId,
      'updated_at': DateTime.now().toIso8601String(),
      'productos_json': productosJson,
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'],
      tipo: map['tipo'] == 'ingreso' ? TransactionType.ingreso : TransactionType.gasto,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha']),
      categoria: map['categoria'],
      descripcion: map['descripcion'],
      clienteId: map['cliente_id'],
      productosJson: map['productos_json'] as String?,
    );
  }
}