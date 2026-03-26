// ─────────────────────────────────────────
// lib/models/incidentModel.dart
// Mapeado a la tabla `incidencias`
// ─────────────────────────────────────────

import 'package:cantillana_incidencias/models/comentarioModel.dart';

/// Valores posibles del campo `estado` en la BD
enum IncidentEstado { pendiente, en_proceso, resuelta, rechazada }

class IncidentModel {
  final int id;
  final int usuarioId; // FK → usuarios.id
  final int categoriaId; // FK → categorias.id
  final String titulo;
  final String descripcion;
  final DateTime fechaCreacion;
  final IncidentEstado estado; // BD almacena como text

  // ── Campos enriquecidos (JOINs) – no están en la tabla incidencias ──────
  final String? categoriaNombre;
  final String? usuarioNombre;
  final List<ComentarioModel> comentarios;

  const IncidentModel({
    required this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.titulo,
    required this.descripcion,
    required this.fechaCreacion,
    this.estado = IncidentEstado.pendiente,
    this.categoriaNombre,
    this.usuarioNombre,
    this.comentarios = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as int,
    usuarioId: json['usuario_id'] as int,
    categoriaId: json['categoria_id'] as int,
    titulo: json['titulo'] as String,
    descripcion: json['descripcion'] as String,
    fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
    estado: IncidentEstado.values.firstWhere(
      (e) => e.name == (json['estado'] as String? ?? 'pendiente'),
      orElse: () => IncidentEstado.pendiente,
    ),
    categoriaNombre: json['categoria_nombre'] as String?,
    usuarioNombre: json['usuario_nombre'] as String?,
    comentarios: (json['comentarios'] as List<dynamic>? ?? [])
        .map((e) => ComentarioModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Solo incluye columnas de la tabla `incidencias`
  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'categoria_id': categoriaId,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'estado': estado.name,
  };

  IncidentModel copyWith({
    int? categoriaId,
    String? titulo,
    String? descripcion,
    IncidentEstado? estado,
    String? categoriaNombre,
    String? usuarioNombre,
    List<ComentarioModel>? comentarios,
  }) => IncidentModel(
    id: id,
    usuarioId: usuarioId,
    categoriaId: categoriaId ?? this.categoriaId,
    titulo: titulo ?? this.titulo,
    descripcion: descripcion ?? this.descripcion,
    fechaCreacion: fechaCreacion,
    estado: estado ?? this.estado,
    categoriaNombre: categoriaNombre ?? this.categoriaNombre,
    usuarioNombre: usuarioNombre ?? this.usuarioNombre,
    comentarios: comentarios ?? this.comentarios,
  );

  // ── Helpers de presentación ─────────────────────────────────────────────
  String get estadoLabel => switch (estado) {
    IncidentEstado.pendiente => 'Pendiente',
    IncidentEstado.en_proceso => 'En Proceso',
    IncidentEstado.resuelta => 'Resuelta',
    IncidentEstado.rechazada => 'Rechazada',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IncidentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
