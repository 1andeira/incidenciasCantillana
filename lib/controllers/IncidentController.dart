// ─────────────────────────────────────────
// lib/controllers/IncidentController.dart
// ─────────────────────────────────────────

import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/models/categoriaModel.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/models/comentarioModel.dart';
import 'package:cantillana_incidencias/models/ubicacionModel.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';

enum SortOption { newest, oldest }

class IncidentController extends GetxController {
  final AuthController authController;
  final _sb = SupabaseService.client;

  IncidentController({required this.authController});

  // ── Estado ───────────────────────────────────────────────────────────────
  final _allIncidents = <IncidentModel>[].obs;
  final categorias = <CategoriaModel>[].obs;

  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var isDetailLoading = false.obs;

  // ── Imágenes pendientes ──────────────────────────────────────────────────
  final _imagePicker = ImagePicker();
  final pendingImages = <String>[].obs;

  // ── Filtros ──────────────────────────────────────────────────────────────
  var searchQuery = ''.obs;
  var selectedCategoriaId = Rxn<int>();
  var selectedEstado = 'all'.obs;
  var sortOption = SortOption.newest.obs;
  var onlyMine = false.obs;

  // ── Vista filtrada ────────────────────────────────────────────────────────
  List<IncidentModel> get incidents {
    var list = _allIncidents.toList();

    if (onlyMine.value) {
      final uid = authController.userId;
      if (uid.isNotEmpty) list = list.where((i) => i.usuarioId == uid).toList();
    }

    if (selectedEstado.value != 'all') {
      final fe = IncidentEstado.values
          .firstWhereOrNull((e) => e.name == selectedEstado.value);
      if (fe != null) list = list.where((i) => i.estado == fe).toList();
    }

    if (selectedCategoriaId.value != null) {
      list = list
          .where((i) => i.categoriaId == selectedCategoriaId.value)
          .toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((i) =>
              i.titulo.toLowerCase().contains(q) ||
              i.descripcion.toLowerCase().contains(q) ||
              (i.categoriaNombre?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    switch (sortOption.value) {
      case SortOption.newest:
        list.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      case SortOption.oldest:
        list.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    }

    return list;
  }

  IncidentModel? getById(int id) =>
      _allIncidents.firstWhereOrNull((i) => i.id == id);

  Rx<IncidentModel?> getByIdRx(int id) {
    final obs = Rx<IncidentModel?>(getById(id));
    ever(_allIncidents, (_) => obs.value = getById(id));
    return obs;
  }

  // ── Estadísticas ──────────────────────────────────────────────────────────
  int get totalCount => _allIncidents.length;
  int get pendingCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.pendiente).length;
  int get inProgressCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.en_proceso).length;
  int get resolvedCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.resuelta).length;

  List<IncidentModel> incidentsByUser(String userId) =>
      _allIncidents.where((i) => i.usuarioId == userId).toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

  // ── Ciclo de vida ─────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _fetchCategorias();
    fetchIncidents();
  }

  // ── Carga ─────────────────────────────────────────────────────────────────
  Future<void> _fetchCategorias() async {
    final rows = await _sb.from('categorias').select().order('id');
    categorias.assignAll(rows.map((r) => CategoriaModel.fromJson(r)));
  }

  Future<void> fetchIncidents() async {
    try {
      isLoading(true);
      hasError(false);
      final rows = await _sb.from('incidencias').select('''
        *,
        categorias ( nombre ),
        usuarios   ( nombre ),
        comentarios (
          *,
          usuarios ( nombre )
        )
      ''').order('fecha_creacion', ascending: false);
      _allIncidents.assignAll(rows.map(_rowToIncident));
    } catch (e) {
      hasError(true);
      errorMessage('Error al cargar las incidencias: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> refresh() => fetchIncidents();

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<IncidentModel?> createIncident({
    required int categoriaId,
    required String titulo,
    required String descripcion,
    double? latitud,
    double? longitud,
    String? descripcionDireccion,
  }) async {
    try {
      isDetailLoading(true);
      final imageUrls = await _uploadPendingImages();
      final uid = authController.userId;
      final row = await _sb.from('incidencias').insert({
        'usuario_id': uid,
        'categoria_id': categoriaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'imagenes': imageUrls,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
        if (descripcionDireccion != null)
          'descripcion_direccion': descripcionDireccion,
      }).select('''
        *,
        categorias ( nombre ),
        usuarios   ( nombre ),
        comentarios ( *, usuarios ( nombre ) )
      ''').single();

      final incident = _rowToIncident(row);
      _allIncidents.insert(0, incident);
      clearPendingImages();
      return incident;
    } catch (e) {
      errorMessage('Error al crear la incidencia: $e');
      return null;
    } finally {
      isDetailLoading(false);
    }
  }

  void updateIncident(IncidentModel updated) {
    final idx = _allIncidents.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _allIncidents[idx] = updated;
      _allIncidents.refresh();
    }
  }

  Future<void> deleteIncident(int id) async {
    await _sb.from('incidencias').delete().eq('id', id);
    _allIncidents.removeWhere((i) => i.id == id);
  }

  // ── Cambio de estado ──────────────────────────────────────────────────────
  Future<void> updateEstado(int id, IncidentEstado nuevoEstado) async {
    final incident = _allIncidents.firstWhereOrNull((i) => i.id == id);
    if (incident == null) return;
    isDetailLoading(true);
    await _sb
        .from('incidencias')
        .update({'estado': nuevoEstado.name}).eq('id', id);
    updateIncident(incident.copyWith(estado: nuevoEstado));
    isDetailLoading(false);
  }

  // ── Comentarios ───────────────────────────────────────────────────────────
  Future<void> addComentario(int incidenciaId, String texto) async {
    final incident =
        _allIncidents.firstWhereOrNull((i) => i.id == incidenciaId);
    if (incident == null) return;
    isDetailLoading(true);
    final uid = authController.userId;
    final row = await _sb
        .from('comentarios')
        .insert({
          'incidencia_id': incidenciaId,
          'usuario_id': uid,
          'comentario': texto.trim(),
        })
        .select('*, usuarios ( nombre )')
        .single();
    final comentario = _rowToComentario(row);
    updateIncident(
        incident.copyWith(comentarios: [...incident.comentarios, comentario]));
    isDetailLoading(false);
  }

  Future<void> deleteComentario(int incidenciaId, int comentarioId) async {
    await _sb.from('comentarios').delete().eq('id', comentarioId);
    final incident =
        _allIncidents.firstWhereOrNull((i) => i.id == incidenciaId);
    if (incident == null) return;
    updateIncident(incident.copyWith(
      comentarios:
          incident.comentarios.where((c) => c.id != comentarioId).toList(),
    ));
  }

  // ── Imágenes ──────────────────────────────────────────────────────────────
  Future<void> pickImagesFromGallery() async {
    try {
      final files = await _imagePicker.pickMultiImage(
          imageQuality: 85, maxWidth: 1024, maxHeight: 1024);
      for (final f in files) {
        if (!pendingImages.contains(f.path)) pendingImages.add(f.path);
      }
    } catch (_) {}
  }

  Future<void> pickImageFromCamera() async {
    try {
      final f = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024);
      if (f != null && !pendingImages.contains(f.path))
        pendingImages.add(f.path);
    } catch (_) {}
  }

  void removeImage(String path) => pendingImages.removeWhere((p) => p == path);
  void clearPendingImages() => pendingImages.clear();

  Future<List<String>> _uploadPendingImages() async {
    final urls = <String>[];
    final uid = authController.userId;
    for (final path in pendingImages) {
      final file = File(path);
      final ext = path.split('.').last;
      final fileName = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';
      await _sb.storage.from('incidencias').upload(fileName, file);
      final url = _sb.storage.from('incidencias').getPublicUrl(fileName);
      urls.add(url);
    }
    return urls;
  }

  // ── Filtros ───────────────────────────────────────────────────────────────
  void clearFilters() {
    searchQuery('');
    selectedEstado.value = 'all';
    selectedCategoriaId.value = null;
    sortOption(SortOption.newest);
    onlyMine(false);
  }

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      selectedEstado.value != 'all' ||
      selectedCategoriaId.value != null ||
      sortOption.value != SortOption.newest ||
      onlyMine.value;

  // ── Mappers ───────────────────────────────────────────────────────────────
  IncidentModel _rowToIncident(Map<String, dynamic> r) {
    final comentariosRaw = (r['comentarios'] as List<dynamic>? ?? []);
    return IncidentModel(
      id: r['id'] as int,
      usuarioId: r['usuario_id'] as String,
      categoriaId: r['categoria_id'] as int,
      titulo: r['titulo'] as String,
      descripcion: r['descripcion'] as String,
      fechaCreacion: DateTime.parse(r['fecha_creacion'] as String),
      estado: IncidentEstado.values.firstWhere(
          (e) => e.name == (r['estado'] ?? 'pendiente'),
          orElse: () => IncidentEstado.pendiente),
      imagenes: List<String>.from(r['imagenes'] ?? []),
      ubicacion: (r['latitud'] != null && r['longitud'] != null)
          ? UbicacionModel(
              latitud: (r['latitud'] as num).toDouble(),
              longitud: (r['longitud'] as num).toDouble(),
              descripcionDireccion: r['descripcion_direccion'] as String?)
          : null,
      categoriaNombre:
          (r['categorias'] as Map<String, dynamic>?)?['nombre'] as String?,
      usuarioNombre:
          (r['usuarios'] as Map<String, dynamic>?)?['nombre'] as String?,
      comentarios: comentariosRaw
          .map((c) => _rowToComentario(c as Map<String, dynamic>))
          .toList(),
    );
  }

  ComentarioModel _rowToComentario(Map<String, dynamic> r) => ComentarioModel(
        id: r['id'] as int,
        incidenciaId: r['incidencia_id'] as int,
        usuarioId: r['usuario_id'] as String,
        comentario: r['comentario'] as String,
        fechaCreacion: DateTime.parse(r['fecha_creacion'] as String),
        usuarioNombre:
            (r['usuarios'] as Map<String, dynamic>?)?['nombre'] as String?,
      );
}
