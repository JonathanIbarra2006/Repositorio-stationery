class Proveedor {
  final String id;
  final String nombre;
  final String contacto; // Teléfono o email
  final String empresa;

  Proveedor({required this.id, required this.nombre, required this.contacto, required this.empresa});

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'contacto': contacto,
    'empresa': empresa,
  };

  factory Proveedor.fromMap(Map<String, dynamic> map) => Proveedor(
    id: map['id'],
    nombre: map['nombre'],
    contacto: map['contacto'],
    empresa: map['empresa'],
  );
}