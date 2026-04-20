class Proveedor {
  final String id;
  final String nombre;
  final String contacto; // Teléfono o email
  final String empresa;
  final String? diasVisita;
  final bool isActive;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.empresa,
    this.diasVisita,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'contacto': contacto,
    'empresa': empresa,
    'dias_visita': diasVisita,
    'is_active': isActive ? 1 : 0,
  };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['id'],
    nombre: map['nombre'],
    contacto: map['contacto'],
    empresa: map['empresa'],
    diasVisita: map['dias_visita'],
    isActive: map['is_active'] == null || map['is_active'] == 1,
  );
}