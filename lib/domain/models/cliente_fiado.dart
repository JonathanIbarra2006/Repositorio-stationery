class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final bool isActive;

  Cliente({required this.id, required this.nombre, this.telefono, this.email, this.isActive = true});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'telefono': telefono,
    'email': email,
    'is_active': isActive ? 1 : 0
  };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      email: map['email'],
      isActive: map['is_active'] == null || map['is_active'] == 1,
  );

  // --- ESTA ES LA SOLUCIÓN AL ERROR DE LA PANTALLA ROJA ---
  // Le enseñamos a Flutter que si dos clientes tienen el mismo ID, son la misma persona.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cliente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
class Fiado {
  final String id;
  final String clienteId;
  final DateTime fecha;
  final double total;
  final String estado; // 'pendiente' o 'pagado'

  Fiado({required this.id, required this.clienteId, required this.fecha, required this.total, required this.estado});

  Map<String, dynamic> toMap() => {
    'id': id, 'cliente_id': clienteId, 'fecha': fecha.toIso8601String(),
    'total': total, 'estado': estado
  };

  factory Fiado.fromMap(Map<String, dynamic> map) => Fiado(
      id: map['id'], clienteId: map['cliente_id'],
      fecha: DateTime.parse(map['fecha']), total: map['total'], estado: map['estado']
  );
}