enum TransactionType { ingreso, gasto }

class AppTransaction {
  final String id;
  final TransactionType tipo;
  final double monto;
  final DateTime fecha;
  final String categoria; // Obligatorio (NOT NULL en SQLite)
  final String descripcion;
  final String? clienteId; // Opcional: para saber qué cliente realizó la compra

  AppTransaction({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    this.clienteId,
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
    );
  }
}