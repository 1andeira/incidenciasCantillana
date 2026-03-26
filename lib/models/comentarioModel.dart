// ─────────────────────────────────────────
// lib/models/comentarioModel.dart
// Mapeado a la tabla `comentarios`
// ─────────────────────────────────────────

class ComentarioModel {
  final int id;
  final int incidenciaId; // FK → incidencias.id
  final int usuarioId; // FK → usuarios.id
  final String comentario;
  final DateTime fechaCreacion;

  /// Campo enriquecido (JOIN con usuarios) – no está en la tabla
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
        usuarioId: json['usuario_id'] as int,
        comentario: json['comentario'] as String,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        usuarioNombre: json['usuario_nombre'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'incidencia_id': incidenciaId,
    'usuario_id': usuarioId,
    'comentario': comentario,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };
}
