// ─────────────────────────────────────────
// lib/models/comentarioModel.dart
// ─────────────────────────────────────────

class ComentarioModel {
  final int id;
  final int incidenciaId;
  final String usuarioId; // UUID de auth.users
  final String comentario;
  final DateTime fechaCreacion;
  final String? usuarioNombre;

  const ComentarioModel({
    required this.id,
    required this.incidenciaId,
    required this.usuarioId,
    required this.comentario,
    required this.fechaCreacion,
    this.usuarioNombre,
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) =>
      ComentarioModel(
        id: json['id'] as int,
        incidenciaId: json['incidencia_id'] as int,
        usuarioId: json['usuario_id'] as String,
        comentario: json['comentario'] as String,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        usuarioNombre:
            (json['usuarios'] as Map<String, dynamic>?)?['nombre'] as String? ??
                json['usuario_nombre'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'incidencia_id': incidenciaId,
        'usuario_id': usuarioId,
        'comentario': comentario,
        'fecha_creacion': fechaCreacion.toIso8601String(),
      };

  ComentarioModel copyWith({String? comentario, String? usuarioNombre}) =>
      ComentarioModel(
        id: id,
        incidenciaId: incidenciaId,
        usuarioId: usuarioId,
        comentario: comentario ?? this.comentario,
        fechaCreacion: fechaCreacion,
        usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      );
}
