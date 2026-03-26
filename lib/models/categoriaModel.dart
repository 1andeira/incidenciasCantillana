// ─────────────────────────────────────────
// lib/models/categoriaModel.dart
// Mapeado a la tabla `categorias`
// ─────────────────────────────────────────

class CategoriaModel {
  final int id;
  final String nombre;

  const CategoriaModel({required this.id, required this.nombre});

  factory CategoriaModel.fromJson(Map<String, dynamic> json) =>
      CategoriaModel(id: json['id'] as int, nombre: json['nombre'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};

  @override
  String toString() => nombre;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoriaModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
