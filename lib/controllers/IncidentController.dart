// lib/controllers/IncidentController.dart

import 'package:get/get.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';

enum SortOption { newest, oldest, priority }

class IncidentController extends GetxController {
  // ── Estado ─────────────────────────────────────────────────────────────
  final _allIncidents = <IncidentModel>[].obs;
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Estado de carga del detalle (para añadir comentarios, etc.)
  var isDetailLoading = false.obs;

  // ── Filtros ─────────────────────────────────────────────────────────────
  var searchQuery = ''.obs;
  // '' = sin filtro activo (centinela para evitar el bug de Rxn con null)
  var selectedCategory = ''.obs;
  // 'all' = sin filtro activo
  var selectedStatus = 'all'.obs;
  var sortOption = SortOption.newest.obs;
  var onlyMine = false.obs;

  // ── Vista filtrada ──────────────────────────────────────────────────────
  List<IncidentModel> get incidents {
    var list = _allIncidents.toList();

    if (onlyMine.value) {
      final uid = _currentUserId;
      if (uid.isNotEmpty) list = list.where((i) => i.userId == uid).toList();
    }
    if (selectedStatus.value != 'all') {
      final filterStatus = IncidentStatus.values.firstWhereOrNull(
        (e) => e.name == selectedStatus.value,
      );
      if (filterStatus != null) {
        list = list.where((i) => i.status == filterStatus).toList();
      }
    }
    if (selectedCategory.value.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.category.toLowerCase() ==
                selectedCategory.value.toLowerCase(),
          )
          .toList();
    }
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.title.toLowerCase().contains(q) ||
                i.description.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q) ||
                (i.address?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    switch (sortOption.value) {
      case SortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }
    return list;
  }

  // ── Obtener por ID ──────────────────────────────────────────────────────
  IncidentModel? getById(String id) =>
      _allIncidents.firstWhereOrNull((i) => i.id == id);

  // Versión reactiva: escucha cambios en _allIncidents y devuelve el modelo actualizado
  Rx<IncidentModel?> getByIdRx(String id) {
    final obs = Rx<IncidentModel?>(getById(id));
    ever(_allIncidents, (_) => obs.value = getById(id));
    return obs;
  }

  // ── Estadísticas ────────────────────────────────────────────────────────
  int get totalCount => _allIncidents.length;
  int get pendingCount =>
      _allIncidents.where((i) => i.status == IncidentStatus.pending).length;
  int get inProgressCount =>
      _allIncidents.where((i) => i.status == IncidentStatus.inProgress).length;
  int get resolvedCount =>
      _allIncidents.where((i) => i.status == IncidentStatus.resolved).length;

  List<IncidentModel> incidentsByUser(String userId) =>
      _allIncidents.where((i) => i.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<String> get availableCategories =>
      _allIncidents.map((i) => i.category).toSet().toList()..sort();

  String get _currentUserId {
    try {
      return Get.find<AuthController>().userId;
    } catch (_) {
      return '';
    }
  }

  // ── Ciclo de vida ───────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchIncidents();
  }

  // ── Carga ───────────────────────────────────────────────────────────────
  Future<void> fetchIncidents() async {
    try {
      isLoading(true);
      hasError(false);
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

  // ── CRUD ────────────────────────────────────────────────────────────────
  void addIncident(IncidentModel incident) => _allIncidents.insert(0, incident);

  void updateIncident(IncidentModel updated) {
    final idx = _allIncidents.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _allIncidents[idx] = updated.copyWith(updatedAt: DateTime.now());
      _allIncidents
          .refresh(); // fuerza rebuild de Obx que observen el mismo objeto
    }
  }

  void deleteIncident(String id) =>
      _allIncidents.removeWhere((i) => i.id == id);

  // ── Cambio de estado con historial ──────────────────────────────────────
  Future<void> updateStatus(
    String id,
    IncidentStatus newStatus, {
    String? comment,
  }) async {
    final incident = _allIncidents.firstWhereOrNull((i) => i.id == id);
    if (incident == null) return;

    isDetailLoading(true);
    await Future.delayed(const Duration(milliseconds: 400)); // simula API

    final entry = StatusHistoryEntry(
      status: newStatus,
      changedAt: DateTime.now(),
      comment: comment,
      changedBy: _currentUserId.isNotEmpty ? _currentUserId : 'system',
    );

    updateIncident(
      incident.copyWith(
        status: newStatus,
        statusHistory: [...incident.statusHistory, entry],
      ),
    );
    isDetailLoading(false);
  }

  // ── Comentarios ─────────────────────────────────────────────────────────
  Future<void> addComment(String incidentId, String text) async {
    final incident = _allIncidents.firstWhereOrNull((i) => i.id == incidentId);
    if (incident == null) return;

    isDetailLoading(true);
    await Future.delayed(const Duration(milliseconds: 300));

    String userName = 'Usuario';
    try {
      final user = Get.find<AuthController>().currentUser.value;
      if (user != null) userName = user.name;
    } catch (_) {}

    final comment = IncidentComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId,
      userName: userName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    updateIncident(
      incident.copyWith(comments: [...incident.comments, comment]),
    );
    isDetailLoading(false);
  }

  Future<void> deleteComment(String incidentId, String commentId) async {
    final incident = _allIncidents.firstWhereOrNull((i) => i.id == incidentId);
    if (incident == null) return;
    updateIncident(
      incident.copyWith(
        comments: incident.comments.where((c) => c.id != commentId).toList(),
      ),
    );
  }

  // ── Filtros ─────────────────────────────────────────────────────────────
  void clearFilters() {
    searchQuery('');
    selectedStatus.value = 'all';
    selectedCategory.value = '';
    sortOption(SortOption.newest);
    onlyMine(false);
  }

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      selectedStatus.value != 'all' ||
      selectedCategory.value.isNotEmpty ||
      sortOption.value != SortOption.newest ||
      onlyMine.value;

  // ── Mock data ───────────────────────────────────────────────────────────
  List<IncidentModel> _mockData() {
    final myId = _currentUserId.isNotEmpty ? _currentUserId : 'u_demo';
    final now = DateTime.now();

    return [
      IncidentModel(
        id: '1',
        userId: myId,
        title: 'Avería Alumbrado Público',
        description:
            'Farola parpadeando constantemente en la calle principal, '
            'justo frente al ayuntamiento. Lleva así más de una semana y '
            'dificulta la visibilidad nocturna en esa zona.',
        category: 'alumbrado',
        status: IncidentStatus.pending,
        priority: IncidentPriority.high,
        address: 'C/ Principal, 12',
        latitude: 37.6050,
        longitude: -5.7949,
        createdAt: now,
        statusHistory: [
          StatusHistoryEntry(
            status: IncidentStatus.pending,
            changedAt: now,
            comment: 'Incidencia registrada',
            changedBy: myId,
          ),
        ],
        comments: [],
      ),
      IncidentModel(
        id: '2',
        userId: 'u_otro',
        title: 'Contenedor Desbordado',
        description:
            'Contenedor de basura completamente desbordado en la zona '
            'del polideportivo. Los residuos están en la vía pública.',
        category: 'limpieza',
        status: IncidentStatus.inProgress,
        priority: IncidentPriority.medium,
        imageUrl: 'https://picsum.photos/seed/bin/800/400',
        address: 'Av. Polideportivo, s/n',
        latitude: 37.6065,
        longitude: -5.7960,
        createdAt: now.subtract(const Duration(days: 1)),
        statusHistory: [
          StatusHistoryEntry(
            status: IncidentStatus.pending,
            changedAt: now.subtract(const Duration(days: 1)),
            comment: 'Incidencia registrada',
            changedBy: 'u_otro',
          ),
          StatusHistoryEntry(
            status: IncidentStatus.inProgress,
            changedAt: now.subtract(const Duration(hours: 10)),
            comment: 'Operarios asignados para recogida esta tarde.',
            changedBy: 'staff_01',
          ),
        ],
        comments: [
          IncidentComment(
            id: 'c1',
            userId: 'u_vecino',
            userName: 'María García',
            text: 'Confirmo el problema, huele muy mal y hay moscas.',
            createdAt: now.subtract(const Duration(hours: 18)),
          ),
          IncidentComment(
            id: 'c2',
            userId: 'staff_01',
            userName: 'Ayuntamiento',
            text: 'Gracias por el aviso. Pasaremos a recogerlo esta tarde.',
            createdAt: now.subtract(const Duration(hours: 9)),
          ),
        ],
      ),
      IncidentModel(
        id: '3',
        userId: myId,
        title: 'Banco del parque roto',
        description:
            'El banco situado junto a la fuente del Parque Municipal tiene '
            'una tabla suelta que puede causar heridas. Hay niños que juegan '
            'en esa zona continuamente.',
        category: 'mobiliario',
        status: IncidentStatus.resolved,
        priority: IncidentPriority.low,
        address: 'Parque Municipal, zona fuente',
        latitude: 37.6040,
        longitude: -5.7935,
        createdAt: now.subtract(const Duration(days: 3)),
        statusHistory: [
          StatusHistoryEntry(
            status: IncidentStatus.pending,
            changedAt: now.subtract(const Duration(days: 3)),
            comment: 'Incidencia registrada',
            changedBy: myId,
          ),
          StatusHistoryEntry(
            status: IncidentStatus.inProgress,
            changedAt: now.subtract(const Duration(days: 2)),
            comment: 'Revisado por el equipo de mantenimiento.',
            changedBy: 'staff_01',
          ),
          StatusHistoryEntry(
            status: IncidentStatus.resolved,
            changedAt: now.subtract(const Duration(days: 1)),
            comment: 'Tabla reemplazada. Banco en perfecto estado.',
            changedBy: 'staff_01',
          ),
        ],
        comments: [
          IncidentComment(
            id: 'c3',
            userId: myId,
            userName: 'Tú',
            text: '¿Hay alguna actualización? Llevo dos días sin noticias.',
            createdAt: now.subtract(const Duration(days: 2, hours: 3)),
          ),
          IncidentComment(
            id: 'c4',
            userId: 'staff_01',
            userName: 'Carlos Ferrera',
            text: 'Ya está arreglado. Gracias por reportarlo.',
            createdAt: now.subtract(const Duration(days: 1, hours: 1)),
          ),
        ],
      ),
      IncidentModel(
        id: '4',
        userId: 'u_otro2',
        title: 'Bache en calzada',
        description:
            'Bache de considerable tamaño a la entrada de la '
            'urbanización Los Álamos. Ya ha provocado al menos un pinchazo '
            'conocido. Muy peligroso para motos.',
        category: 'viales',
        status: IncidentStatus.pending,
        priority: IncidentPriority.high,
        imageUrl: 'https://picsum.photos/seed/road/800/400',
        address: 'Ctra. de Sevilla, km 3',
        latitude: 37.6080,
        longitude: -5.7920,
        createdAt: now.subtract(const Duration(hours: 5)),
        statusHistory: [
          StatusHistoryEntry(
            status: IncidentStatus.pending,
            changedAt: now.subtract(const Duration(hours: 5)),
            comment: 'Incidencia registrada',
            changedBy: 'u_otro2',
          ),
        ],
        comments: [],
      ),
    ];
  }
}
