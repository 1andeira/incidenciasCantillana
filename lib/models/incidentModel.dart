// ─────────────────────────────────────────
// lib/models/incidentModel.dart
// ─────────────────────────────────────────

import 'package:cantillana_incidencias/models/comentarioModel.dart';
import 'package:cantillana_incidencias/models/ubicacionModel.dart';

enum IncidentEstado { pendiente, en_proceso, resuelta, rechazada }

class IncidentModel {
  final int id;
  final String usuarioId; // UUID de auth.users
  final int categoriaId;
  final String titulo;
  final String descripcion;
  final DateTime fechaCreacion;
  final IncidentEstado estado;
  final List<String> imagenes; // URLs públicas del bucket Supabase
  final UbicacionModel? ubicacion; // Columnas planas en la BD

  // ── Campos enriquecidos (JOINs) ─────────────────────────────────────────
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
    this.imagenes = const [],
    this.ubicacion,
    this.categoriaNombre,
    this.usuarioNombre,
    this.comentarios = const [],
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as String,
        categoriaId: json['categoria_id'] as int,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String,
        fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
        estado: IncidentEstado.values.firstWhere(
          (e) => e.name == (json['estado'] as String? ?? 'pendiente'),
          orElse: () => IncidentEstado.pendiente,
        ),
        imagenes: (json['imagenes'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        ubicacion: (json['latitud'] != null && json['longitud'] != null)
            ? UbicacionModel(
                latitud: (json['latitud'] as num).toDouble(),
                longitud: (json['longitud'] as num).toDouble(),
                descripcionDireccion: json['descripcion_direccion'] as String?,
              )
            : null,
        categoriaNombre: json['categoria_nombre'] as String?,
        usuarioNombre: json['usuario_nombre'] as String?,
        comentarios: (json['comentarios'] as List<dynamic>? ?? [])
            .map((e) => ComentarioModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Solo columnas de la tabla `incidencias`
  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'categoria_id': categoriaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'estado': estado.name,
        'imagenes': imagenes,
        if (ubicacion != null) ...{
          'latitud': ubicacion!.latitud,
          'longitud': ubicacion!.longitud,
          'descripcion_direccion': ubicacion!.descripcionDireccion,
        },
      };

  IncidentModel copyWith({
    int? categoriaId,
    String? titulo,
    String? descripcion,
    IncidentEstado? estado,
    List<String>? imagenes,
    UbicacionModel? ubicacion,
    bool clearUbicacion = false,
    String? categoriaNombre,
    String? usuarioNombre,
    List<ComentarioModel>? comentarios,
  }) =>
      IncidentModel(
        id: id,
        usuarioId: usuarioId,
        categoriaId: categoriaId ?? this.categoriaId,
        titulo: titulo ?? this.titulo,
        descripcion: descripcion ?? this.descripcion,
        fechaCreacion: fechaCreacion,
        estado: estado ?? this.estado,
        imagenes: imagenes ?? this.imagenes,
        ubicacion: clearUbicacion ? null : (ubicacion ?? this.ubicacion),
        categoriaNombre: categoriaNombre ?? this.categoriaNombre,
        usuarioNombre: usuarioNombre ?? this.usuarioNombre,
        comentarios: comentarios ?? this.comentarios,
      );

  // ── Helpers ──────────────────────────────────────────────────────────────
  String get estadoLabel => switch (estado) {
        IncidentEstado.pendiente => 'Pendiente',
        IncidentEstado.en_proceso => 'En Proceso',
        IncidentEstado.resuelta => 'Resuelta',
        IncidentEstado.rechazada => 'Rechazada',
      };

  bool get hasImages => imagenes.isNotEmpty;
  bool get hasUbicacion => ubicacion != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IncidentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
