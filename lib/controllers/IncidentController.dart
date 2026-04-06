// ─────────────────────────────────────────
// lib/controllers/IncidentController.dart
// ─────────────────────────────────────────

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/models/categoriaModel.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/models/comentarioModel.dart';

/// Sin SortOption.priority (no existe en el esquema)
enum SortOption { newest, oldest }

class IncidentController extends GetxController {
  final AuthController authController;

  IncidentController({required this.authController});

  // ── Estado ──────────────────────────────────────────────────────────────
  final _allIncidents = <IncidentModel>[].obs;
  final categorias = <CategoriaModel>[].obs;

  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var isDetailLoading = false.obs;

  // ── Imágenes ────────────────────────────────────────────────────────────
  final _imagePicker = ImagePicker();
  final pendingImages = <String>[].obs;

  // ── Filtros ─────────────────────────────────────────────────────────────
  var searchQuery = ''.obs;
  var selectedCategoriaId = Rxn<int>(); // null = todas las categorías
  var selectedEstado = 'all'.obs; // 'all' = sin filtro de estado
  var sortOption = SortOption.newest.obs;
  var onlyMine = false.obs;

  // ── Vista filtrada ───────────────────────────────────────────────────────
  List<IncidentModel> get incidents {
    var list = _allIncidents.toList();

    if (onlyMine.value) {
      final uid = _currentUserId;
      if (uid != 0) list = list.where((i) => i.usuarioId == uid).toList();
    }
    if (selectedEstado.value != 'all') {
      final filterEstado = IncidentEstado.values.firstWhereOrNull(
        (e) => e.name == selectedEstado.value,
      );
      if (filterEstado != null) {
        list = list.where((i) => i.estado == filterEstado).toList();
      }
    }
    if (selectedCategoriaId.value != null) {
      list = list
          .where((i) => i.categoriaId == selectedCategoriaId.value)
          .toList();
    }
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.titulo.toLowerCase().contains(q) ||
                i.descripcion.toLowerCase().contains(q) ||
                (i.categoriaNombre?.toLowerCase().contains(q) ?? false),
          )
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

  // ── Obtener por ID ───────────────────────────────────────────────────────
  IncidentModel? getById(int id) =>
      _allIncidents.firstWhereOrNull((i) => i.id == id);

  Rx<IncidentModel?> getByIdRx(int id) {
    final obs = Rx<IncidentModel?>(getById(id));
    ever(_allIncidents, (_) => obs.value = getById(id));
    return obs;
  }

  // ── Estadísticas ─────────────────────────────────────────────────────────
  int get totalCount => _allIncidents.length;
  int get pendingCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.pendiente).length;
  int get inProgressCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.en_proceso).length;
  int get resolvedCount =>
      _allIncidents.where((i) => i.estado == IncidentEstado.resuelta).length;

  List<IncidentModel> incidentsByUser(int userId) =>
      _allIncidents.where((i) => i.usuarioId == userId).toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

  int get _currentUserId => authController.userId;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _fetchCategorias();
    fetchIncidents();
  }

  // ── Carga ──────────────────────────────────────────────────────────────────
  Future<void> _fetchCategorias() async {
    // Simula SELECT * FROM categorias
    await Future.delayed(const Duration(milliseconds: 300));
    categorias.assignAll(_mockCategorias());
  }

  Future<void> fetchIncidents() async {
    try {
      isLoading(true);
      hasError(false);
      // Simula SELECT i.*, c.nombre AS categoria_nombre, u.nombre AS usuario_nombre
      //         FROM incidencias i
      //         JOIN categorias c ON c.id = i.categoria_id
      //         JOIN usuarios u   ON u.id = i.usuario_id
      await Future.delayed(const Duration(seconds: 2));
      _allIncidents.assignAll(_mockData());
    } catch (e) {
      hasError(true);
      errorMessage('Error al cargar las incidencias: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> refresh() => fetchIncidents();

  // ── CRUD ────────────────────────────────────────────────────────────────────
  void addIncident(IncidentModel incident) => _allIncidents.insert(0, incident);

  void updateIncident(IncidentModel updated) {
    final idx = _allIncidents.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _allIncidents[idx] = updated;
      _allIncidents.refresh();
    }
  }

  void deleteIncident(int id) => _allIncidents.removeWhere((i) => i.id == id);

  // ── Cambio de estado ─────────────────────────────────────────────────────
  /// Simula UPDATE incidencias SET estado=$1 WHERE id=$2
  Future<void> updateEstado(int id, IncidentEstado nuevoEstado) async {
    final incident = _allIncidents.firstWhereOrNull((i) => i.id == id);
    if (incident == null) return;

    isDetailLoading(true);
    await Future.delayed(const Duration(milliseconds: 400));
    updateIncident(incident.copyWith(estado: nuevoEstado));
    isDetailLoading(false);
  }

  // ── Comentarios ──────────────────────────────────────────────────────────
  /// Simula INSERT INTO comentarios (incidencia_id, usuario_id, comentario)
  Future<void> addComentario(int incidenciaId, String texto) async {
    final incident = _allIncidents.firstWhereOrNull(
      (i) => i.id == incidenciaId,
    );
    if (incident == null) return;

    isDetailLoading(true);
    await Future.delayed(const Duration(milliseconds: 300));

    String userName = 'Usuario';
    int uid = 0;

    final user = authController.currentUser.value;
    if (user != null) {
      userName = user.nombre;
      uid = user.id;
    }

    final comentario = ComentarioModel(
      id: DateTime.now().millisecondsSinceEpoch,
      incidenciaId: incidenciaId,
      usuarioId: uid,
      comentario: texto.trim(),
      fechaCreacion: DateTime.now(),
      usuarioNombre: userName,
    );

    updateIncident(
      incident.copyWith(comentarios: [...incident.comentarios, comentario]),
    );
    isDetailLoading(false);
  }

  /// Simula DELETE FROM comentarios WHERE id=$1
  Future<void> deleteComentario(int incidenciaId, int comentarioId) async {
    final incident = _allIncidents.firstWhereOrNull(
      (i) => i.id == incidenciaId,
    );
    if (incident == null) return;
    updateIncident(
      incident.copyWith(
        comentarios:
            incident.comentarios.where((c) => c.id != comentarioId).toList(),
      ),
    );
  }

  // ── Gestión de imágenes ─────────────────────────────────────────────────
  /// Abre el selector de imágenes de la galería
  Future<void> pickImagesFromGallery() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          if (!pendingImages.contains(file.path)) {
            pendingImages.add(file.path);
          }
        }
      }
    } catch (e) {
      // Manejo de error (usuario canceló o permisos denegados)
    }
  }

  /// Abre la cámara para capturar una imagen
  Future<void> pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        if (!pendingImages.contains(pickedFile.path)) {
          pendingImages.add(pickedFile.path);
        }
      }
    } catch (e) {
      // Manejo de error (usuario canceló o permisos denegados)
    }
  }

  /// Elimina una imagen del conjunto pendiente
  void removeImage(String imagePath) {
    pendingImages.removeWhere((img) => img == imagePath);
  }

  /// Limpia todas las imágenes pendientes
  void clearPendingImages() {
    pendingImages.clear();
  }

  // ── Filtros ──────────────────────────────────────────────────────────────────
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

  // ── Mock: SELECT * FROM categorias ──────────────────────────────────────────
  List<CategoriaModel> _mockCategorias() => [
        const CategoriaModel(id: 1, nombre: 'Alumbrado'),
        const CategoriaModel(id: 2, nombre: 'Limpieza'),
        const CategoriaModel(id: 3, nombre: 'Mobiliario'),
        const CategoriaModel(id: 4, nombre: 'Viales'),
        const CategoriaModel(id: 5, nombre: 'Otros'),
      ];

  // ── Mock: SELECT con JOINs ───────────────────────────────────────────────────
  List<IncidentModel> _mockData() {
    final myId = _currentUserId != 0 ? _currentUserId : 99;
    final now = DateTime.now();

    return [
      IncidentModel(
        id: 1,
        usuarioId: myId,
        categoriaId: 1,
        titulo: 'Avería Alumbrado Público',
        descripcion: 'Farola parpadeando constantemente en la calle principal, '
            'justo frente al ayuntamiento. Lleva así más de una semana y '
            'dificulta la visibilidad nocturna en esa zona.',
        fechaCreacion: now,
        estado: IncidentEstado.pendiente,
        categoriaNombre: 'Alumbrado',
        usuarioNombre: 'Demo Usuario',
        comentarios: [],
      ),
      IncidentModel(
        id: 2,
        usuarioId: 2,
        categoriaId: 2,
        titulo: 'Contenedor Desbordado',
        descripcion: 'Contenedor de basura completamente desbordado en la zona '
            'del polideportivo. Los residuos están en la vía pública.',
        fechaCreacion: now.subtract(const Duration(days: 1)),
        estado: IncidentEstado.en_proceso,
        categoriaNombre: 'Limpieza',
        usuarioNombre: 'María García',
        comentarios: [
          ComentarioModel(
            id: 101,
            incidenciaId: 2,
            usuarioId: 3,
            comentario: 'Confirmo el problema, huele muy mal y hay moscas.',
            fechaCreacion: now.subtract(const Duration(hours: 18)),
            usuarioNombre: 'Pedro López',
          ),
          ComentarioModel(
            id: 102,
            incidenciaId: 2,
            usuarioId: 10,
            comentario:
                'Gracias por el aviso. Pasaremos a recogerlo esta tarde.',
            fechaCreacion: now.subtract(const Duration(hours: 9)),
            usuarioNombre: 'Ayuntamiento',
          ),
        ],
      ),
      IncidentModel(
        id: 3,
        usuarioId: myId,
        categoriaId: 3,
        titulo: 'Banco del parque roto',
        descripcion:
            'El banco situado junto a la fuente del Parque Municipal tiene '
            'una tabla suelta que puede causar heridas. Hay niños que '
            'juegan en esa zona continuamente.',
        fechaCreacion: now.subtract(const Duration(days: 3)),
        estado: IncidentEstado.resuelta,
        categoriaNombre: 'Mobiliario',
        usuarioNombre: 'Demo Usuario',
        comentarios: [
          ComentarioModel(
            id: 103,
            incidenciaId: 3,
            usuarioId: myId,
            comentario:
                '¿Hay alguna actualización? Llevo dos días sin noticias.',
            fechaCreacion: now.subtract(const Duration(days: 2, hours: 3)),
            usuarioNombre: 'Demo Usuario',
          ),
          ComentarioModel(
            id: 104,
            incidenciaId: 3,
            usuarioId: 10,
            comentario: 'Ya está arreglado. Gracias por reportarlo.',
            fechaCreacion: now.subtract(const Duration(days: 1, hours: 1)),
            usuarioNombre: 'Carlos Ferrera',
          ),
        ],
      ),
      IncidentModel(
        id: 4,
        usuarioId: 5,
        categoriaId: 4,
        titulo: 'Bache en calzada',
        descripcion: 'Bache de considerable tamaño a la entrada de la '
            'urbanización Los Álamos. Ya ha provocado al menos un pinchazo '
            'conocido. Muy peligroso para motos.',
        fechaCreacion: now.subtract(const Duration(hours: 5)),
        estado: IncidentEstado.pendiente,
        categoriaNombre: 'Viales',
        usuarioNombre: 'Ana Martínez',
        comentarios: [],
      ),
    ];
  }
}
