// ─────────────────────────────────────────
// lib/screens/incident_detail_screen.dart
// OPTIMIZADO - Colores del escudo sin redundancias
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

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
          backgroundColor: CantillanaTheme.verdeOscuro,
          appBar: AppBar(backgroundColor: CantillanaTheme.rojo),
          body: const Center(
            child: Text(
              'Incidencia no encontrada',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      return _DetailView(incident: incident, controller: ctrl);
    });
  }
}

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

  String get _currentUserId {
    try {
      return Get.find<AuthController>().userId;
    } catch (_) {
      return '';
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
    return Scaffold(
      backgroundColor: CantillanaTheme.verdeOscuro,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (inc.imageUrl != null) _HeroImage(url: inc.imageUrl!),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IncidentHeader(
                        incident: inc,
                        isOwner: _isOwner,
                        onStatusTap: _showStatusSheet,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'Descripción'),
                      const SizedBox(height: 8),
                      Text(
                        inc.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Detalles'),
                      const SizedBox(height: 12),
                      _DetailsCard(incident: inc),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Historial de estado'),
                      const SizedBox(height: 12),
                      _StatusTimeline(history: inc.statusHistory),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _CommentInput(
        controller: _commentCtrl,
        focusNode: _commentFocus,
        incidentCtrl: ctrl,
        incidentId: inc.id,
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: CantillanaTheme.rojo,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: CantillanaTheme.verdeOscuro,
            onSelected: (value) {
              if (value == 'status') _showStatusSheet();
              if (value == 'share') _share();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_outlined,
                      color: CantillanaTheme.dorado,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cambiar estado',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: CantillanaTheme.dorado),
                    const SizedBox(width: 12),
                    const Text(
                      'Compartir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: CantillanaTheme.rojo),
                    const SizedBox(width: 12),
                    Text(
                      'Eliminar',
                      style: TextStyle(color: CantillanaTheme.rojo),
                    ),
                  ],
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Compartir',
          onPressed: _share,
        ),
      ],
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CantillanaTheme.verdeOscuro,
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CantillanaTheme.verdeOscuro,
        title: const Text(
          'Eliminar incidencia',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Continuar?',
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
              ctrl.deleteIncident(inc.id);
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _share() {
    final text =
        '📍 Incidencia en Cantillana\n'
        '${inc.title}\n'
        'Estado: ${inc.statusLabel}\n'
        '${inc.address ?? ''}\n'
        'Reportada el ${DateFormat('dd/MM/yyyy').format(inc.createdAt)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado al portapapeles'),
        backgroundColor: CantillanaTheme.rojo,
      ),
    );
  }
}

// ─────────────────────────────────────────
// Widgets principales
// ─────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String url;
  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          children: [
            Image.network(
              url,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      color: Colors.black26,
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
                color: Colors.black26,
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            ),
            // Indicador de que es tappable
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Ver imagen',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Imagen en pantalla completa
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Center(
                          child: CircularProgressIndicator(
                            color: CantillanaTheme.dorado,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image, color: Colors.white38, size: 64),
                ),
              ),
            ),
            // Botón cerrar
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CantillanaTheme.rojo,
                    shape: BoxShape.circle,
                    border: Border.all(color: CantillanaTheme.dorado, width: 2),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          incident.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(
              status: incident.status,
              isOwner: isOwner,
              onTap: isOwner ? onStatusTap : null,
            ),
            _PriorityBadge(priority: incident.priority),
            _CategoryBadge(category: incident.category),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IncidentStatus status;
  final bool isOwner;
  final VoidCallback? onTap;

  const _StatusBadge({required this.status, required this.isOwner, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            _label(),
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
  );

  Color _color() => switch (status) {
    IncidentStatus.pending => Colors.orange,
    IncidentStatus.inProgress => Colors.blue,
    IncidentStatus.resolved => Colors.green,
    IncidentStatus.rejected => CantillanaTheme.rojo,
  };

  IconData _icon() => switch (status) {
    IncidentStatus.pending => Icons.hourglass_empty,
    IncidentStatus.inProgress => Icons.autorenew,
    IncidentStatus.resolved => Icons.check_circle_outline,
    IncidentStatus.rejected => Icons.cancel_outlined,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Color(0xFF1B5E20),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color(), width: 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(), size: 14, color: _color()),
        const SizedBox(width: 4),
        Text(
          'Prioridad ${_label()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color(),
          ),
        ),
      ],
    ),
  );

  Color _color() => switch (priority) {
    IncidentPriority.high => Colors.red.shade300,
    IncidentPriority.medium => Colors.orange.shade300,
    IncidentPriority.low => Colors.green.shade300,
  };

  IconData _icon() => switch (priority) {
    IncidentPriority.high => Icons.keyboard_double_arrow_up,
    IncidentPriority.medium => Icons.drag_handle,
    IncidentPriority.low => Icons.keyboard_double_arrow_down,
  };

  String _label() => switch (priority) {
    IncidentPriority.high => 'Alta',
    IncidentPriority.medium => 'Media',
    IncidentPriority.low => 'Baja',
  };
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: CantillanaTheme.dorado.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: CantillanaTheme.dorado, width: 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(), size: 14, color: CantillanaTheme.dorado),
        const SizedBox(width: 4),
        Text(
          category.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CantillanaTheme.dorado,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  IconData _icon() => switch (category.toLowerCase()) {
    'alumbrado' => Icons.lightbulb_outline,
    'limpieza' => Icons.cleaning_services_outlined,
    'mobiliario' => Icons.chair_outlined,
    'viales' => Icons.construction,
    _ => Icons.report_problem_outlined,
  };
}

class _DetailsCard extends StatelessWidget {
  final IncidentModel incident;
  const _DetailsCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.tag,
            label: 'Referencia',
            value: '#${incident.id.padLeft(4, '0')}',
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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: CantillanaTheme.dorado),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 48,
    color: CantillanaTheme.dorado.withOpacity(0.2),
  );
}

class _MapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _MapPreview({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final mapUrl =
        'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$latitude,$longitude&zoom=16&size=600x200'
        '&maptype=mapnik&markers=$latitude,$longitude,red-pushpin';

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
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
              color: Colors.black26,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, color: Colors.white38, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final List<StatusHistoryEntry> history;
  const _StatusTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Sin historial de cambios',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    final sorted = [...history]
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));

    return Column(
      children: sorted
          .asMap()
          .entries
          .map(
            (e) => _TimelineItem(
              entry: e.value,
              isLast: e.key == sorted.length - 1,
              isFirst: e.key == 0,
            ),
          )
          .toList(),
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
    final color = _statusColor(entry.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: CantillanaTheme.dorado.withOpacity(0.3),
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
                      color: CantillanaTheme.dorado.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                          color: isLast ? color : Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(entry.changedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.comment!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
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
    IncidentStatus.rejected => CantillanaTheme.rojo,
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Sé el primero en comentar',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isOwn
                ? CantillanaTheme.rojo.withOpacity(0.3)
                : CantillanaTheme.dorado.withOpacity(0.3),
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isOwn ? CantillanaTheme.rojo : CantillanaTheme.dorado,
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white54,
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
                    color: Color(0xFF1B5E20),
                    border: Border.all(
                      color: isOwn
                          ? CantillanaTheme.rojo
                          : CantillanaTheme.dorado,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isOwn ? 12 : 2),
                      topRight: Radius.circular(isOwn ? 2 : 12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white,
                    ),
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
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: CantillanaTheme.verdeOscuro,
        border: Border(
          top: BorderSide(color: CantillanaTheme.dorado, width: 2),
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
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario…',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF1B5E20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: CantillanaTheme.dorado,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: CantillanaTheme.dorado,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: CantillanaTheme.dorado,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => incidentCtrl.isDetailLoading.value
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CantillanaTheme.dorado,
                        ),
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: () => _submit(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: CantillanaTheme.rojo,
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(
                          color: CantillanaTheme.dorado,
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Icon(Icons.send, size: 18),
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CantillanaTheme.dorado,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                  Text(
                    _statusLabel(s),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              value: s,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: CantillanaTheme.dorado,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Añade una nota (opcional)…',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF1B5E20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CantillanaTheme.dorado, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CantillanaTheme.dorado, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: CantillanaTheme.dorado, width: 3),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                backgroundColor: CantillanaTheme.rojo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: CantillanaTheme.dorado, width: 3),
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
    IncidentStatus.rejected => CantillanaTheme.rojo,
  };

  String _statusLabel(IncidentStatus s) => switch (s) {
    IncidentStatus.pending => 'Pendiente',
    IncidentStatus.inProgress => 'En Proceso',
    IncidentStatus.resolved => 'Resuelta',
    IncidentStatus.rejected => 'Rechazada',
  };
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionLabel({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: CantillanaTheme.dorado,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: CantillanaTheme.rojo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
