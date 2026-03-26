// ─────────────────────────────────────────
// lib/models/userModel.dart
// Mapeado a la tabla `usuarios`
// ─────────────────────────────────────────

class UserModel {
  final int id;
  final String nombre;
  final String? email; // UNIQUE en BD, nullable
  final String? telefono; // UNIQUE en BD, nullable
  final DateTime fechaRegistro;

  // `contrasena` nunca se almacena en el modelo por seguridad

  const UserModel({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    required this.fechaRegistro,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    email: json['email'] as String?,
    telefono: json['telefono'] as String?,
    fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
    'fecha_registro': fechaRegistro.toIso8601String(),
  };

  UserModel copyWith({String? nombre, String? email, String? telefono}) =>
      UserModel(
        id: id,
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        telefono: telefono ?? this.telefono,
        fechaRegistro: fechaRegistro,
      );

  String get initials {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  /// Identificador visible: email si existe, si no teléfono
  String get contacto => email ?? telefono ?? 'Sin contacto';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
