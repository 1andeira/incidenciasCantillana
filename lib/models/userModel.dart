// ─────────────────────────────────────────
// lib/models/userModel.dart
// ─────────────────────────────────────────

enum UserRol { admin, usuario }

class UserModel {
  final String id; // UUID de auth.users
  final String nombre;
  final String? email;
  final String? telefono;
  final DateTime fechaRegistro;
  final UserRol rol;

  const UserModel({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    required this.fechaRegistro,
    this.rol = UserRol.usuario,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        email: json['email'] as String?,
        telefono: json['telefono'] as String?,
        fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
        rol: parseRol(json['rol'] as String?),
      );

  static UserRol parseRol(String? value) {
    if (value == 'admin') return UserRol.admin;
    return UserRol.usuario;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'fecha_registro': fechaRegistro.toIso8601String(),
        'rol': rol.name,
      };

  UserModel copyWith({
    String? nombre,
    String? email,
    String? telefono,
    UserRol? rol,
  }) =>
      UserModel(
        id: id,
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        telefono: telefono ?? this.telefono,
        fechaRegistro: fechaRegistro,
        rol: rol ?? this.rol,
      );

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool get isAdmin => rol == UserRol.admin;

  String get initials {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  String get contacto => email ?? telefono ?? 'Sin contacto';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
