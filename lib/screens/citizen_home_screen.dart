// ─────────────────────────────────────────
// lib/screens/citizen_home_screen.dart
// VERSIÓN CORREGIDA - Colores directos sin mezclas
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen>
    with SingleTickerProviderStateMixin {
  late final IncidentController _controller;
  late final AnimationController _fabAnimation;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(IncidentController());
    _fabAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnimation.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CantillanaTheme.verdeOscuro,
      appBar: AppBar(
        backgroundColor: CantillanaTheme.rojo,
        title: _showSearch
            ? _SearchBar(
                controller: _searchController,
                onChanged: (v) => _controller.searchQuery(v),
                onClose: () {
                  setState(() => _showSearch = false);
                  _searchController.clear();
                  _controller.searchQuery('');
                },
              )
            : const _AppBarTitle(),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Buscar',
              onPressed: () => setState(() => _showSearch = true),
            ),
          Obx(
            () => _showSearch
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Badge(
                      isLabelVisible: _controller.hasActiveFilters,
                      backgroundColor: CantillanaTheme.dorado,
                      child: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                    tooltip: 'Filtrar',
                    onPressed: () => _showFilterSheet(context),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) return const _LoadingView();
        if (_controller.hasError.value) {
          return _ErrorView(
            message: _controller.errorMessage.value,
            onRetry: _controller.refresh,
          );
        }
        return Column(
          children: [
            _StatsHeader(controller: _controller),
            _FilterChips(controller: _controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                color: CantillanaTheme.rojo,
                child: _controller.incidents.isEmpty
                    ? _EmptyView(
                        hasFilters: _controller.hasActiveFilters,
                        onClear: _controller.clearFilters,
                      )
                    : _IncidentList(controller: _controller),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimation,
          curve: Curves.easeOutBack,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-incident'),
          backgroundColor: CantillanaTheme.rojo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Reporte'),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CantillanaTheme.verdeOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(controller: _controller),
    );
  }
}

// ─────────────────────────────────────────
// AppBar widgets
// ─────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Escudo pequeño
      Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: CantillanaTheme.dorado.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/cantillan.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.location_city,
              size: 16,
              color: CantillanaTheme.rojo,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Incidencias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            'Cantillana',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    ],
  );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: true,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white70,
    decoration: InputDecoration(
      hintText: 'Buscar incidencias…',
      hintStyle: const TextStyle(color: Colors.white60),
      border: InputBorder.none,
      suffixIcon: IconButton(
        icon: const Icon(Icons.close, color: Colors.white70),
        onPressed: onClose,
      ),
    ),
    onChanged: onChanged,
  );
}

// ─────────────────────────────────────────
// Header estadísticas
// ─────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final IncidentController controller;
  const _StatsHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CantillanaTheme.rojo,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: controller.totalCount,
            color: Colors.white24,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Pendiente',
            value: controller.pendingCount,
            color: Colors.orange.withOpacity(.35),
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'En proceso',
            value: controller.inProgressCount,
            color: Colors.blue.withOpacity(.35),
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Resueltas',
            value: controller.resolvedCount,
            color: Colors.green.withOpacity(.35),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────
// Chips de filtro
// ─────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final IncidentController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.availableCategories;
      return Container(
        color: CantillanaTheme.verdeOscuro,
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: [
            // Chip "Mis incidencias"
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  Icons.person_pin_outlined,
                  size: 16,
                  color: controller.onlyMine.value
                      ? Colors.white
                      : CantillanaTheme.rojo,
                ),
                label: const Text('Mis incidencias'),
                selected: controller.onlyMine.value,
                selectedColor: CantillanaTheme.rojo,
                backgroundColor: Color(0xFF1B5E20),
                checkmarkColor: Colors.white,
                side: BorderSide(color: CantillanaTheme.dorado, width: 2),
                labelStyle: TextStyle(
                  color: controller.onlyMine.value
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: controller.onlyMine.value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (_) =>
                    controller.onlyMine(!controller.onlyMine.value),
              ),
            ),

            // Divisor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: VerticalDivider(
                color: CantillanaTheme.dorado,
                width: 1,
                thickness: 2,
              ),
            ),
            const SizedBox(width: 4),

            // Chips de categoría
            _categoryChip(context, null, 'Todas'),
            ...categories.map((c) => _categoryChip(context, c, _cap(c))),
          ],
        ),
      );
    });
  }

  Widget _categoryChip(BuildContext context, String? value, String label) {
    final selected = value == null
        ? controller.selectedCategory.value.isEmpty
        : controller.selectedCategory.value == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.selectedCategory.value = value ?? '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? CantillanaTheme.rojo : Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CantillanaTheme.dorado,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────
// Lista de incidencias
// ─────────────────────────────────────────

class _IncidentList extends StatelessWidget {
  final IncidentController controller;
  const _IncidentList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final list = controller.incidents;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final incident = list[index];
        return _AnimatedCard(
          key: ValueKey(incident.id),
          index: index,
          child: _IncidentCard(
            incident: incident,
            onDelete: () => _confirmDelete(context, incident, controller),
            onStatusTap: () => _showStatusPicker(context, incident, controller),
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    IncidentModel incident,
    IncidentController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CantillanaTheme.verdeOscuro,
        title: const Text(
          'Eliminar incidencia',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${incident.title}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: CantillanaTheme.dorado),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CantillanaTheme.rojo,
              side: BorderSide(color: CantillanaTheme.dorado, width: 2),
            ),
            onPressed: () {
              ctrl.deleteIncident(incident.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Incidencia eliminada'),
                  backgroundColor: CantillanaTheme.rojo,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(
    BuildContext context,
    IncidentModel incident,
    IncidentController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CantillanaTheme.verdeOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StatusPickerSheet(
        current: incident.status,
        onPick: (s) {
          ctrl.updateStatus(incident.id, s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// Tarjeta animada
// ─────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({super.key, required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 60), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ─────────────────────────────────────────
// Tarjeta de incidencia
// ─────────────────────────────────────────

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onDelete;
  final VoidCallback onStatusTap;

  const _IncidentCard({
    required this.incident,
    required this.onDelete,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isOwner = auth.userId == incident.userId;

    return Dismissible(
      key: ValueKey(incident.id),
      direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CantillanaTheme.rojo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CantillanaTheme.dorado, width: 3),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CantillanaTheme.dorado, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/incident/${incident.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryIcon(category: incident.category),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    incident.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'Tu incidencia',
                                    child: Icon(
                                      Icons.person_pin,
                                      size: 16,
                                      color: CantillanaTheme.dorado,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              incident.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: CantillanaTheme.dorado,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: isOwner ? onStatusTap : null,
                        child: _StatusBadge(status: incident.status),
                      ),
                    ],
                  ),

                  if (incident.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        incident.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : SizedBox(
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: CantillanaTheme.dorado,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.black38,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white38,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Text(
                    incident.description,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (incident.address != null) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            incident.address!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      _PriorityBadge(priority: incident.priority),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(incident.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final String category;
  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CantillanaTheme.dorado.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Icon(_icon(), color: CantillanaTheme.dorado, size: 20),
    );
  }

  IconData _icon() => switch (category.toLowerCase()) {
    'alumbrado' => Icons.lightbulb_outline,
    'limpieza' => Icons.cleaning_services_outlined,
    'mobiliario' => Icons.chair_outlined,
    'viales' => Icons.construction,
    _ => Icons.report_problem_outlined,
  };
}

class _StatusBadge extends StatelessWidget {
  final IncidentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _color(),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CantillanaTheme.dorado, width: 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _label(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
      ],
    ),
  );

  Color _color() => switch (status) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => CantillanaTheme.rojo,
  };

  String _label() => switch (status) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };
}

class _PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(_icon(), size: 14, color: _color()),
      const SizedBox(width: 2),
      Text(_label(), style: TextStyle(fontSize: 11, color: _color())),
    ],
  );

  IconData _icon() => switch (priority) {
    IncidentPriority.high => Icons.keyboard_double_arrow_up,
    IncidentPriority.medium => Icons.drag_handle,
    IncidentPriority.low => Icons.keyboard_double_arrow_down,
  };

  Color _color() => switch (priority) {
    IncidentPriority.high => Colors.red.shade300,
    IncidentPriority.medium => Colors.orange.shade300,
    IncidentPriority.low => Colors.green.shade300,
  };

  String _label() => switch (priority) {
    IncidentPriority.high => 'Alta',
    IncidentPriority.medium => 'Media',
    IncidentPriority.low => 'Baja',
  };
}

// ─────────────────────────────────────────
// Bottom sheets
// ─────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final IncidentController controller;
  const _FilterSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CantillanaTheme.dorado,
                  ),
                ),
                if (controller.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Limpiar todo',
                      style: TextStyle(color: CantillanaTheme.rojo),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _filterChip(
                  context,
                  null,
                  'Todos',
                  controller.selectedStatus.value == 'all',
                ),
                ...IncidentStatus.values.map(
                  (s) => _filterChip(
                    context,
                    s,
                    _statusLabel(s),
                    controller.selectedStatus.value == s.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ordenar por',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SortOption.values
                  .map(
                    (o) => ChoiceChip(
                      label: Text(_sortLabel(o)),
                      selected: controller.sortOption.value == o,
                      onSelected: (_) => controller.sortOption(o),
                      selectedColor: CantillanaTheme.rojo,
                      backgroundColor: Color(0xFF1B5E20),
                      side: BorderSide(color: CantillanaTheme.dorado, width: 2),
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: controller.sortOption.value == o
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    IncidentStatus? value,
    String label,
    bool selected,
  ) => GestureDetector(
    onTap: () =>
        controller.selectedStatus.value = value == null ? 'all' : value.name,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? CantillanaTheme.rojo : Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: Colors.white,
        ),
      ),
    ),
  );

  String _statusLabel(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };

  String _sortLabel(SortOption o) => switch (o) {
    SortOption.newest => 'Más reciente',
    SortOption.oldest => 'Más antiguo',
    SortOption.priority => 'Prioridad',
  };
}

class _StatusPickerSheet extends StatelessWidget {
  final IncidentStatus current;
  final ValueChanged<IncidentStatus> onPick;

  const _StatusPickerSheet({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambiar estado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CantillanaTheme.dorado,
          ),
        ),
        const SizedBox(height: 16),
        ...IncidentStatus.values.map(
          (s) => ListTile(
            leading: CircleAvatar(backgroundColor: _statusColor(s), radius: 10),
            title: Text(_statusLabel(s), style: TextStyle(color: Colors.white)),
            trailing: current == s
                ? Icon(Icons.check, color: CantillanaTheme.dorado)
                : null,
            onTap: () => onPick(s),
          ),
        ),
      ],
    ),
  );

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => CantillanaTheme.rojo,
  };

  String _statusLabel(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };
}

// ─────────────────────────────────────────
// Estados vacío / carga / error
// ─────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: CantillanaTheme.dorado),
        const SizedBox(height: 16),
        const Text(
          'Cargando incidencias…',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 64, color: CantillanaTheme.dorado),
          const SizedBox(height: 16),
          const Text(
            'Algo salió mal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: CantillanaTheme.rojo,
              side: BorderSide(color: CantillanaTheme.dorado, width: 3),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyView({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasFilters ? Icons.search_off : Icons.check_circle_outline,
          size: 72,
          color: CantillanaTheme.dorado,
        ),
        const SizedBox(height: 16),
        Text(
          hasFilters
              ? 'Sin resultados para estos filtros'
              : 'No hay incidencias reportadas',
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        if (hasFilters) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: CantillanaTheme.dorado, width: 2),
              foregroundColor: CantillanaTheme.dorado,
            ),
            child: const Text('Limpiar filtros'),
          ),
        ],
      ],
    ),
  );
}
