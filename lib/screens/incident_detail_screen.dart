// ─────────────────────────────────────────
// lib/screens/incident_detail_screen.dart
// Detalle completo de una incidencia
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/models/comentarioModel.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  late final IncidentController _ctrl;
  late final AuthController _auth;
  late Rx<IncidentModel?> _incidentRx;

  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<IncidentController>();
    _auth = Get.find<AuthController>();
    final id = int.tryParse(widget.incidentId) ?? 0;
    _incidentRx = _ctrl.getByIdRx(id);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
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

  // ── Cambiar estado ────────────────────────────────────────────────────────
  void _showChangeEstado(IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: CantillanaTheme.verdeOscuro,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border:
              Border(top: BorderSide(color: CantillanaTheme.dorado, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text('Cambiar estado',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...IncidentEstado.values.map((e) {
              final isSelected = e == incident.estado;
              final color = _colorEstado(e);
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.6)),
                  ),
                  child: Icon(_iconEstado(e), color: color, size: 18),
                ),
                title: Text(incident.copyWith(estado: e).estadoLabel,
                    style: TextStyle(
                        color: isSelected ? color : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing:
                    isSelected ? Icon(Icons.check_circle, color: color) : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _ctrl.updateEstado(incident.id, e);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Enviar comentario ─────────────────────────────────────────────────────
  Future<void> _sendComment(int incidenciaId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    await _ctrl.addComentario(incidenciaId, text);
    // Hacer scroll al final
    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final incident = _incidentRx.value;

      if (incident == null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Incidencia'),
            leading: IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back)),
          ),
          body: const Center(
            child: Text('Incidencia no encontrada',
                style: TextStyle(color: Colors.white70)),
          ),
        );
      }

      final color = _colorEstado(incident.estado);
      final df = DateFormat('dd/MM/yyyy – HH:mm');
      final currentUserId = _auth.userId;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Incidencia #${incident.id}',
            style: const TextStyle(fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          actions: [
            // Botón de cambiar estado
            Obx(() => _ctrl.isDetailLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Cambiar estado',
                    onPressed: () => _showChangeEstado(incident),
                  )),
          ],
        ),

        // ── Cuerpo ────────────────────────────────────────────────────────
        body: Column(
          children: [
            // Barra de estado
            Container(
              width: double.infinity,
              color: color.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(_iconEstado(incident.estado), size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(incident.estadoLabel,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Spacer(),
                  if (incident.categoriaNombre != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: CantillanaTheme.dorado.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: CantillanaTheme.dorado.withOpacity(0.5)),
                      ),
                      child: Text(
                        incident.categoriaNombre!,
                        style: const TextStyle(
                            color: CantillanaTheme.dorado,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // Contenido scrollable
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  // ── Título ────────────────────────────────────────────
                  Text(
                    incident.titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3),
                  ),
                  const SizedBox(height: 8),

                  // ── Meta: usuario y fecha ─────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(incident.usuarioNombre ?? 'Desconocido',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(df.format(incident.fechaCreacion),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),

                  // ── Descripción ───────────────────────────────────────
                  const Text('Descripción',
                      style: TextStyle(
                          color: CantillanaTheme.dorado,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      incident.descripcion,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Comentarios ───────────────────────────────────────
                  Row(
                    children: [
                      const Text('Comentarios',
                          style: TextStyle(
                              color: CantillanaTheme.dorado,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          incident.comentarios.length.toString(),
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (incident.comentarios.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Aún no hay comentarios. ¡Sé el primero!',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...incident.comentarios.map((c) => _CommentBubble(
                          comment: c,
                          isOwn: c.usuarioId == currentUserId,
                          onDelete: currentUserId == c.usuarioId
                              ? () => _ctrl.deleteComentario(incident.id, c.id)
                              : null,
                        )),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Campo de comentario ───────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0E4023),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario…',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                  const SizedBox(width: 8),
                  Obx(() => _ctrl.isDetailLoading.value
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: CantillanaTheme.dorado))),
                        )
                      : GestureDetector(
                          onTap: () => _sendComment(incident.id),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CantillanaTheme.rojo,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: CantillanaTheme.dorado, width: 1.5),
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────
// Burbuja de comentario
// ─────────────────────────────────────────
class _CommentBubble extends StatelessWidget {
  final ComentarioModel comment;
  final bool isOwn;
  final VoidCallback? onDelete;

  const _CommentBubble(
      {required this.comment, required this.isOwn, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isOwn ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isOwn ? CantillanaTheme.dorado : Colors.white24,
                      width: 1.5),
                ),
                child: Center(
                  child: Text(
                    (comment.usuarioNombre?.isNotEmpty == true
                        ? comment.usuarioNombre![0].toUpperCase()
                        : '?'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comment.usuarioNombre ?? 'Desconocido',
                  style: TextStyle(
                    color: isOwn ? CantillanaTheme.dorado : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(df.format(comment.fechaCreacion),
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              if (onDelete != null)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminar comentario'),
                      content: const Text(
                          '¿Seguro que quieres eliminar este comentario?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          child: const Text('Eliminar',
                              style: TextStyle(color: CantillanaTheme.rojo)),
                        ),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.delete_outline,
                        size: 16, color: Colors.white38),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOwn
                  ? CantillanaTheme.rojo.withOpacity(0.12)
                  : const Color(0xFF1A5C32),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: isOwn
                    ? CantillanaTheme.rojo.withOpacity(0.3)
                    : Colors.white12,
              ),
            ),
            child: Text(comment.comentario,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
