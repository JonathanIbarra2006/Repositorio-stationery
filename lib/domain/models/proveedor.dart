class Proveedor {
  final String id;
  final String nombre;
  final String contacto; // Teléfono o email
  final String empresa;
  final String? diasVisita;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.empresa,
    this.diasVisita,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'contacto': contacto,
    'empresa': empresa,
    'dias_visita': diasVisita,
  };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['id'],
    nombre: map['nombre'],
    contacto: map['contacto'],
    empresa: map['empresa'],
    diasVisita: map['dias_visita'],
  );
}