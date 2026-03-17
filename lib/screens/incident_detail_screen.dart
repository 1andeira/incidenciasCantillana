// lib/screens/incident_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<IncidentController>();
    final incidentRx = ctrl.getByIdRx(incidentId);

    return Obx(() {
      final incident = incidentRx.value;
      if (incident == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Incidencia no encontrada')),
        );
      }
      return _DetailView(incident: incident, controller: ctrl);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista principal
// ─────────────────────────────────────────────────────────────────────────────

class _DetailView extends StatefulWidget {
  final IncidentModel incident;
  final IncidentController controller;

  const _DetailView({required this.incident, required this.controller});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  IncidentModel get inc => widget.incident;
  IncidentController get ctrl => widget.controller;

  bool get _isOwner {
    try {
      return Get.find<AuthController>().userId == inc.userId;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(context, cs),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Imagen ────────────────────────────────────────────────
                if (inc.imageUrl != null) _HeroImage(url: inc.imageUrl!),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cabecera: categoría + prioridad + estado ───────
                      _IncidentHeader(
                        incident: inc,
                        isOwner: _isOwner,
                        onStatusTap: () => _showStatusSheet(context),
                      ),

                      const SizedBox(height: 20),

                      // ── Descripción ────────────────────────────────────
                      _SectionLabel(label: 'Descripción'),
                      const SizedBox(height: 8),
                      Text(
                        inc.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Detalles ───────────────────────────────────────
                      _SectionLabel(label: 'Detalles'),
                      const SizedBox(height: 12),
                      _DetailsCard(incident: inc),

                      const SizedBox(height: 24),

                      // ── Línea de tiempo ────────────────────────────────
                      _SectionLabel(label: 'Historial de estado'),
                      const SizedBox(height: 12),
                      _StatusTimeline(history: inc.statusHistory),

                      const SizedBox(height: 24),

                      // ── Comentarios ────────────────────────────────────
                      _SectionLabel(
                        label: 'Comentarios',
                        count: inc.comments.length,
                      ),
                      const SizedBox(height: 12),
                      _CommentsList(
                        incident: inc,
                        controller: ctrl,
                        currentUserId: _currentUserId,
                      ),

                      // Espacio para el campo de texto flotante
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Campo de comentario fijo abajo ─────────────────────────────────
      bottomSheet: _CommentInput(
        controller: _commentCtrl,
        focusNode: _commentFocus,
        incidentCtrl: ctrl,
        incidentId: inc.id,
      ),
    );
  }

  // ── SliverAppBar con degradado sobre la imagen ──────────────────────────
  SliverAppBar _buildAppBar(BuildContext context, ColorScheme cs) {
    return SliverAppBar(
      expandedHeight: inc.imageUrl != null ? 0 : 0,
      pinned: true,
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      title: Text(
        inc.category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        if (_isOwner)
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (action) => _handleMenu(context, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _MenuAction.changeStatus,
                child: ListTile(
                  leading: Icon(Icons.swap_horiz_outlined),
                  title: Text('Cambiar estado'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _MenuAction.share,
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Compartir'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _MenuAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Compartir',
          onPressed: () => _share(context),
        ),
      ],
    );
  }

  void _handleMenu(BuildContext context, _MenuAction action) {
    switch (action) {
      case _MenuAction.changeStatus:
        _showStatusSheet(context);
      case _MenuAction.share:
        _share(context);
      case _MenuAction.delete:
        _confirmDelete(context);
    }
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _ChangeStatusSheet(
        current: inc.status,
        onConfirm: (status, comment) async {
          Navigator.pop(context);
          await ctrl.updateStatus(inc.id, status, comment: comment);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar incidencia'),
        content: const Text('Esta acción no se puede deshacer. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ctrl.deleteIncident(inc.id);
              Navigator.pop(context); // cierra diálogo
              context.pop(); // vuelve a la lista
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    final text =
        '📍 Incidencia en Cantillana\n'
        '${inc.title}\n'
        'Estado: ${inc.statusLabel}\n'
        '${inc.address ?? ''}\n'
        'Reportada el ${DateFormat('dd/MM/yyyy').format(inc.createdAt)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  String get _currentUserId {
    try {
      return Get.find<AuthController>().userId;
    } catch (_) {
      return '';
    }
  }
}

enum _MenuAction { changeStatus, share, delete }

// ─────────────────────────────────────────────────────────────────────────────
// Imagen hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String url;
  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[100],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabecera de la incidencia
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentHeader extends StatelessWidget {
  final IncidentModel incident;
  final bool isOwner;
  final VoidCallback onStatusTap;

  const _IncidentHeader({
    required this.incident,
    required this.isOwner,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          incident.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),

        // Fila de badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Estado (tappable si es propietario)
            GestureDetector(
              onTap: isOwner ? onStatusTap : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(incident.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(incident.status),
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      incident.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.white70, size: 12),
                    ],
                  ],
                ),
              ),
            ),

            // Prioridad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _priorityColor(incident.priority).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _priorityColor(incident.priority).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _priorityIcon(incident.priority),
                    size: 14,
                    color: _priorityColor(incident.priority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prioridad ${incident.priorityLabel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _priorityColor(incident.priority),
                    ),
                  ),
                ],
              ),
            ),

            // Categoría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(incident.category),
                    size: 14,
                    color: cs.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    incident.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => Colors.red,
  };

  IconData _statusIcon(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Icons.hourglass_empty,
    IncidentStatus.inProgress => Icons.autorenew,
    IncidentStatus.resolved => Icons.check_circle_outline,
    IncidentStatus.rejected => Icons.cancel_outlined,
  };

  Color _priorityColor(IncidentPriority p) => switch (p) {
    IncidentPriority.high => Colors.red,
    IncidentPriority.medium => Colors.orange,
    IncidentPriority.low => Colors.green,
  };

  IconData _priorityIcon(IncidentPriority p) => switch (p) {
    IncidentPriority.high => Icons.keyboard_double_arrow_up,
    IncidentPriority.medium => Icons.drag_handle,
    IncidentPriority.low => Icons.keyboard_double_arrow_down,
  };

  IconData _categoryIcon(String cat) => switch (cat.toLowerCase()) {
    'alumbrado' => Icons.lightbulb_outline,
    'limpieza' => Icons.cleaning_services_outlined,
    'mobiliario' => Icons.chair_outlined,
    'viales' => Icons.construction,
    _ => Icons.report_problem_outlined,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de detalles
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final IncidentModel incident;
  const _DetailsCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.tag,
            label: 'Referencia',
            value: '#${incident.id.padLeft(4, '0')}',
            isFirst: true,
          ),
          _DetailDivider(),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha de reporte',
            value: DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt),
          ),
          if (incident.updatedAt != null) ...[
            _DetailDivider(),
            _DetailRow(
              icon: Icons.update_outlined,
              label: 'Última actualización',
              value: DateFormat('dd/MM/yyyy HH:mm').format(incident.updatedAt!),
            ),
          ],
          if (incident.address != null) ...[
            _DetailDivider(),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: incident.address!,
            ),
          ],
          if (incident.latitude != null && incident.longitude != null) ...[
            _DetailDivider(),
            _MapPreview(
              latitude: incident.latitude!,
              longitude: incident.longitude!,
              address: incident.address ?? '',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 48,
    endIndent: 0,
    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview estática del mapa (banner sin dependencias externas)
// ─────────────────────────────────────────────────────────────────────────────

class _MapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String address;

  const _MapPreview({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // URL de mapa estático usando OpenStreetMap tiles (sin API key)
    final mapUrl =
        'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latitude,$longitude&zoom=16&size=600x200'
        '&maptype=mapnik&markers=$latitude,$longitude,red-pushpin';

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Stack(
        children: [
          Image.network(
            mapUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: cs.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: cs.onSurface.withOpacity(0.3),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$latitude, $longitude',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Overlay con coordenadas
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${latitude.toStringAsFixed(4)}, '
                '${longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline de estado
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final List<StatusHistoryEntry> history;
  const _StatusTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _emptyHint(context, 'Sin historial de cambios de estado');
    }

    final sorted = [...history]
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));

    return Column(
      children: List.generate(sorted.length, (i) {
        final entry = sorted[i];
        final isLast = i == sorted.length - 1;
        return _TimelineItem(entry: entry, isLast: isLast, isFirst: i == 0);
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final StatusHistoryEntry entry;
  final bool isLast;
  final bool isFirst;

  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(entry.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Línea + punto ──────────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  )
                else
                  const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isLast ? color : color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: isLast ? 0 : 2),
                  ),
                  child: Icon(
                    _statusIcon(entry.status),
                    size: 14,
                    color: isLast ? Colors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: 2,
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Contenido ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isLast ? color : null,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(entry.changedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                  if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.comment!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => Colors.red,
  };

  IconData _statusIcon(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Icons.hourglass_empty,
    IncidentStatus.inProgress => Icons.autorenew,
    IncidentStatus.resolved => Icons.check_circle_outline,
    IncidentStatus.rejected => Icons.cancel_outlined,
  };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return DateFormat('dd/MM/yy').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de comentarios
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsList extends StatelessWidget {
  final IncidentModel incident;
  final IncidentController controller;
  final String currentUserId;

  const _CommentsList({
    required this.incident,
    required this.controller,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (incident.comments.isEmpty) {
      return _emptyHint(context, 'Sé el primero en comentar');
    }

    return Column(
      children: incident.comments
          .map(
            (c) => _CommentBubble(
              comment: c,
              isOwn: c.userId == currentUserId,
              onDelete: c.userId == currentUserId
                  ? () => controller.deleteComment(incident.id, c.id)
                  : null,
            ),
          )
          .toList(),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final IncidentComment comment;
  final bool isOwn;
  final VoidCallback? onDelete;

  const _CommentBubble({
    required this.comment,
    required this.isOwn,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isOwn
                ? cs.primaryContainer
                : cs.secondaryContainer,
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isOwn ? cs.primary : cs.secondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: cs.onSurface.withOpacity(0.35),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? cs.primaryContainer.withOpacity(0.4)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isOwn ? 12 : 2),
                      topRight: Radius.circular(isOwn ? 2 : 12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return DateFormat('dd/MM/yy').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de comentario (bottom sheet fijo)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final IncidentController incidentCtrl;
  final String incidentId;

  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.incidentCtrl,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario…',
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: incidentCtrl.isDetailLoading.value
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : FilledButton(
                      onPressed: () => _submit(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(44, 44),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.send, size: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    focusNode.unfocus();
    incidentCtrl.addComment(incidentId, text);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: cambiar estado con comentario opcional
// ─────────────────────────────────────────────────────────────────────────────

class _ChangeStatusSheet extends StatefulWidget {
  final IncidentStatus current;
  final Future<void> Function(IncidentStatus, String?) onConfirm;

  const _ChangeStatusSheet({required this.current, required this.onConfirm});

  @override
  State<_ChangeStatusSheet> createState() => _ChangeStatusSheetState();
}

class _ChangeStatusSheetState extends State<_ChangeStatusSheet> {
  late IncidentStatus _selected;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Cambiar estado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Opciones de estado
          ...IncidentStatus.values.map(
            (s) => RadioListTile<IncidentStatus>(
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(_statusLabel(s)),
                ],
              ),
              value: s,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // Comentario opcional
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Añade una nota (opcional)…',
              filled: true,
              fillColor: cs.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón confirmar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == widget.current
                  ? null
                  : () {
                      final note = _commentCtrl.text.trim();
                      widget.onConfirm(
                        _selected,
                        note.isNotEmpty ? note : null,
                      );
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirmar cambio'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => Colors.red,
  };

  String _statusLabel(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionLabel({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: cs.primary,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Widget _emptyHint(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 16),
  child: Center(
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
        fontSize: 13,
      ),
    ),
  ),
);
