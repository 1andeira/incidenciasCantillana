// ─────────────────────────────────────────
// lib/models/ubicacionModel.dart
// Coordenadas geográficas de una incidencia
// ─────────────────────────────────────────

class UbicacionModel {
  final double latitud;
  final double longitud;
  final String? descripcionDireccion; // Dirección legible opcional

  const UbicacionModel({
    required this.latitud,
    required this.longitud,
    this.descripcionDireccion,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) => UbicacionModel(
        latitud: (json['latitud'] as num).toDouble(),
        longitud: (json['longitud'] as num).toDouble(),
        descripcionDireccion: json['descripcion_direccion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'latitud': latitud,
        'longitud': longitud,
        'descripcion_direccion': descripcionDireccion,
      };

  UbicacionModel copyWith({
    double? latitud,
    double? longitud,
    String? descripcionDireccion,
  }) =>
      UbicacionModel(
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        descripcionDireccion: descripcionDireccion ?? this.descripcionDireccion,
      );

  /// Coordenadas formateadas para mostrar al usuario
  String get coordenadasLabel =>
      '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';

  /// URL para abrir en Google Maps app o web
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud';

  @override
  String toString() => 'UbicacionModel($latitud, $longitud)';
}
