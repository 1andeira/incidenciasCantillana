// ─────────────────────────────────────────
// lib/screens/citizen_home_screen.dart
// Lista principal de incidencias con filtros
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/widget/cantillana_loading.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  late final IncidentController _ctrl;
  final AuthController _auth = Get.find<AuthController>();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(IncidentController(authController: _auth));
    _searchCtrl.addListener(() => _ctrl.searchQuery(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _colorEstado(IncidentEstado e) => switch (e) {
        IncidentEstado.pendiente => CantillanaTheme.estadoPendiente,
        IncidentEstado.en_proceso => CantillanaTheme.estadoEnProceso,
        IncidentEstado.resuelta => CantillanaTheme.estadoResuelta,
        IncidentEstado.rechazada => CantillanaTheme.estadoRechazada,
      };

  IconData _iconEstado(IncidentEstado e) => switch (e) {
        IncidentEstado.pendiente => Icons.schedule,
        IncidentEstado.en_proceso => Icons.autorenew,
        IncidentEstado.resuelta => Icons.check_circle_outline,
        IncidentEstado.rechazada => Icons.cancel_outlined,
      };

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(ctrl: _ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: CantillanaTheme.dorado, width: 1.5),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/cantillan.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.location_city,
                        size: 16,
                        color: CantillanaTheme.rojo),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cantillana',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Incidencias',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white70, height: 1)),
              ],
            ),
          ],
        ),
        actions: [
          Obx(() {
            final initials = _auth.user?.initials ?? '?';
            final _ = _auth.user?.nombre;
            return GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CantillanaTheme.dorado,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // ── Estadísticas ──────────────────────────────────────────────
          Obx(() {
            final _ = _ctrl.totalCount +
                _ctrl.pendingCount +
                _ctrl.inProgressCount +
                _ctrl.resolvedCount;
            return _StatsRow(ctrl: _ctrl);
          }),

          // ── Búsqueda + filtros ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar incidencia…',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: CantillanaTheme.dorado, size: 20),
                        suffixIcon: Obx(() {
                          final _ = _ctrl.searchQuery.value;
                          return _ctrl.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.white54),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _ctrl.searchQuery('');
                                  },
                                )
                              : const SizedBox.shrink();
                        }),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: const Color(0xFF1B5E20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: CantillanaTheme.dorado, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: CantillanaTheme.dorado, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: CantillanaTheme.dorado, width: 2.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final _ = _ctrl.hasActiveFilters;
                  return _FilterButton(
                      active: _ctrl.hasActiveFilters, onTap: _showFilters);
                }),
              ],
            ),
          ),

          // ── Filtros activos ───────────────────────────────────────────
          Obx(() {
            final hasFilters = _ctrl.hasActiveFilters;
            final _ = _ctrl.hasActiveFilters;
            if (!hasFilters) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  const Text('Filtros activos',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _ctrl.clearFilters();
                      _searchCtrl.clear();
                    },
                    child: Text('Limpiar todo',
                        style: TextStyle(
                            color: CantillanaTheme.dorado,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final isLoading = _ctrl.isLoading.value;
              final hasError = _ctrl.hasError.value;
              final errorMessage = _ctrl.errorMessage.value;
              final list = _ctrl.incidents;
              final _ = [
                _ctrl.isLoading.value,
                _ctrl.hasError.value,
                _ctrl.incidents.length
              ];
              if (isLoading) {
                return const CantillanaLoadingInline(
                    message: 'Cargando incidencias…');
              }
              if (hasError) {
                return _ErrorView(
                    message: errorMessage, onRetry: _ctrl.refresh);
              }
              if (list.isEmpty) return const _EmptyView();
              return RefreshIndicator(
                color: CantillanaTheme.dorado,
                backgroundColor: CantillanaTheme.verdeOscuro,
                onRefresh: _ctrl.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _IncidentCard(
                    incident: list[i],
                    colorEstado: _colorEstado(list[i].estado),
                    iconEstado: _iconEstado(list[i].estado),
                    onTap: () => context.go('/incident/${list[i].id}'),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-incident'),
        backgroundColor: CantillanaTheme.rojo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label:
            const Text('Nueva', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: CantillanaTheme.dorado, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Estadísticas
// ─────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final IncidentController ctrl;
  const _StatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E4023),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
              label: 'Total', value: ctrl.totalCount, color: Colors.white70),
          _StatChip(
              label: 'Pendiente',
              value: ctrl.pendingCount,
              color: CantillanaTheme.estadoPendiente),
          _StatChip(
              label: 'En Proceso',
              value: ctrl.inProgressCount,
              color: CantillanaTheme.estadoEnProceso),
          _StatChip(
              label: 'Resuelta',
              value: ctrl.resolvedCount,
              color: CantillanaTheme.estadoResuelta),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value.toString(),
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Tarjeta de incidencia
// ─────────────────────────────────────────
class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final Color colorEstado;
  final IconData iconEstado;
  final VoidCallback onTap;

  const _IncidentCard({
    required this.incident,
    required this.colorEstado,
    required this.iconEstado,
    required this.onTap,
  });

  Future<void> _abrirEnMaps(BuildContext context) async {
    final uri = Uri.parse(incident.ubicacion!.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir Google Maps'),
            backgroundColor: CantillanaTheme.rojo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Material(
      color: const Color(0xFF1A5C32),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: colorEstado, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título + estado ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.titulo,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EstadoBadge(
                      estado: incident.estado,
                      color: colorEstado,
                      icon: iconEstado),
                ],
              ),
              const SizedBox(height: 6),

              // ── Descripción ─────────────────────────────────────────
              Text(
                incident.descripcion,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Meta: categoría · fecha · ubicación · comentarios ───
              Row(
                children: [
                  if (incident.categoriaNombre != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CantillanaTheme.dorado.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: CantillanaTheme.dorado.withOpacity(0.5)),
                      ),
                      child: Text(incident.categoriaNombre!,
                          style: TextStyle(
                              color: CantillanaTheme.dorado,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.calendar_today,
                      size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(df.format(incident.fechaCreacion),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
                  const Spacer(),

                  // ── Badge de ubicación: toca para abrir Maps ─────────
                  if (incident.hasUbicacion) ...[
                    GestureDetector(
                      onTap: () => _abrirEnMaps(context),
                      // Evitar que el tap suba al InkWell del card
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: CantillanaTheme.dorado.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: CantillanaTheme.dorado.withOpacity(0.55)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 11, color: CantillanaTheme.dorado),
                            SizedBox(width: 3),
                            Text('Ver mapa',
                                style: TextStyle(
                                    color: CantillanaTheme.dorado,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  if (incident.comentarios.isNotEmpty) ...[
                    const Icon(Icons.comment_outlined,
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 3),
                    Text(incident.comentarios.length.toString(),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Colors.white38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Badge de estado
// ─────────────────────────────────────────
class _EstadoBadge extends StatelessWidget {
  final IncidentEstado estado;
  final Color color;
  final IconData icon;
  const _EstadoBadge(
      {required this.estado, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            estado.name == 'en_proceso'
                ? 'En Proceso'
                : estado.name.capitalize!,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Botón de filtros
// ─────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CantillanaTheme.dorado, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.tune, color: Colors.white, size: 20),
            if (active)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CantillanaTheme.dorado,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Bottom sheet de filtros
// ─────────────────────────────────────────
class _FiltersSheet extends StatelessWidget {
  final IncidentController ctrl;
  const _FiltersSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: CantillanaTheme.verdeOscuro,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border:
              Border(top: BorderSide(color: CantillanaTheme.dorado, width: 3)),
        ),
        child: Obx(() {
          final _ = ctrl.onlyMine.value.toString() +
              ctrl.selectedEstado.value +
              (ctrl.selectedCategoriaId.value?.toString() ?? '') +
              ctrl.sortOption.value.toString() +
              ctrl.categorias.length.toString();
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text('Filtros',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _FilterSection(title: 'Mis incidencias', children: [
                SwitchListTile(
                  value: ctrl.onlyMine.value,
                  onChanged: (v) => ctrl.onlyMine(v),
                  title: const Text('Solo mis incidencias',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  activeColor: CantillanaTheme.dorado,
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
              _FilterSection(title: 'Estado', children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _EstadoChip(
                        label: 'Todos',
                        value: 'all',
                        selected: ctrl.selectedEstado.value,
                        onTap: (v) => ctrl.selectedEstado(v)),
                    _EstadoChip(
                        label: 'Pendiente',
                        value: 'pendiente',
                        selected: ctrl.selectedEstado.value,
                        onTap: (v) => ctrl.selectedEstado(v)),
                    _EstadoChip(
                        label: 'En Proceso',
                        value: 'en_proceso',
                        selected: ctrl.selectedEstado.value,
                        onTap: (v) => ctrl.selectedEstado(v)),
                    _EstadoChip(
                        label: 'Resuelta',
                        value: 'resuelta',
                        selected: ctrl.selectedEstado.value,
                        onTap: (v) => ctrl.selectedEstado(v)),
                    _EstadoChip(
                        label: 'Rechazada',
                        value: 'rechazada',
                        selected: ctrl.selectedEstado.value,
                        onTap: (v) => ctrl.selectedEstado(v)),
                  ],
                ),
              ]),
              _FilterSection(title: 'Categoría', children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CategoriaChip(
                      label: 'Todas',
                      selected: ctrl.selectedCategoriaId.value == null,
                      onTap: () => ctrl.selectedCategoriaId.value = null,
                    ),
                    ...ctrl.categorias.map((c) => _CategoriaChip(
                          label: c.nombre,
                          selected: ctrl.selectedCategoriaId.value == c.id,
                          onTap: () => ctrl.selectedCategoriaId.value = c.id,
                        )),
                  ],
                ),
              ]),
              _FilterSection(title: 'Ordenar', children: [
                Row(
                  children: [
                    _SortChip(
                      label: 'Más recientes',
                      selected: ctrl.sortOption.value == SortOption.newest,
                      onTap: () => ctrl.sortOption(SortOption.newest),
                    ),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Más antiguas',
                      selected: ctrl.sortOption.value == SortOption.oldest,
                      onTap: () => ctrl.sortOption(SortOption.oldest),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ctrl.clearFilters();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: CantillanaTheme.rojo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: CantillanaTheme.dorado),
                        ),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FilterSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: CantillanaTheme.dorado,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _EstadoChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? CantillanaTheme.dorado : Colors.white24),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoriaChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? CantillanaTheme.dorado : Colors.white24),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? CantillanaTheme.dorado : Colors.white24),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Estados vacío / error
// ─────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: CantillanaTheme.dorado.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No hay incidencias',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Prueba a cambiar los filtros o crea una nueva.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: CantillanaTheme.rojo),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style:
                  FilledButton.styleFrom(backgroundColor: CantillanaTheme.rojo),
            ),
          ],
        ),
      ),
    );
  }
}
