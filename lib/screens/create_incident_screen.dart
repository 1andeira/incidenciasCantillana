// ─────────────────────────────────────────
// lib/screens/create_incident_screen.dart
// Formulario de nueva incidencia
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/categoriaModel.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';

class CreateIncidentScreen extends StatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  State<CreateIncidentScreen> createState() => _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends State<CreateIncidentScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = Get.find<IncidentController>();
  final _auth = Get.find<AuthController>();

  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  CategoriaModel? _selectedCategoria;
  bool _isSubmitting = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── Límites de carácter ─────────────────────────────────────────────────
  static const int _tituloMax = 80;
  static const int _descMax = 500;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoria == null) {
      _showError('Selecciona una categoría para continuar.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Simula INSERT INTO incidencias
    await Future.delayed(const Duration(milliseconds: 700));

    final userId = _auth.userId != 0 ? _auth.userId : 1;
    final newIncident = IncidentModel(
      id: DateTime.now().millisecondsSinceEpoch % 1000000,
      usuarioId: userId,
      categoriaId: _selectedCategoria!.id,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      fechaCreacion: DateTime.now(),
      estado: IncidentEstado.pendiente,
      categoriaNombre: _selectedCategoria!.nombre,
      usuarioNombre: _auth.user?.nombre ?? 'Desconocido',
    );

    _ctrl.addIncident(newIncident);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: CantillanaTheme.dorado),
              SizedBox(width: 8),
              Text('Incidencia creada correctamente'),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go('/incident/${newIncident.id}');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(msg),
          ],
        ),
        backgroundColor: CantillanaTheme.rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Nueva Incidencia'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cabecera informativa ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CantillanaTheme.dorado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: CantillanaTheme.dorado.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: CantillanaTheme.dorado, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Describe el problema con el mayor detalle posible para que podamos atenderte mejor.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Título ──────────────────────────────────────────────
                  _SectionLabel(text: 'Título de la incidencia *'),
                  const SizedBox(height: 8),
                  _buildTituloField(),

                  const SizedBox(height: 20),

                  // ── Categoría ───────────────────────────────────────────
                  _SectionLabel(text: 'Categoría *'),
                  const SizedBox(height: 8),
                  Obx(() => _buildCategoriaGrid(_ctrl.categorias)),

                  const SizedBox(height: 20),

                  // ── Descripción ─────────────────────────────────────────
                  _SectionLabel(text: 'Descripción *'),
                  const SizedBox(height: 8),
                  _buildDescripcionField(),

                  const SizedBox(height: 28),

                  // ── Resumen antes de enviar ─────────────────────────────
                  Obx(() {
                    final hasData = _tituloCtrl.text.isNotEmpty ||
                        _descripcionCtrl.text.isNotEmpty ||
                        _selectedCategoria != null;
                    if (!hasData) return const SizedBox.shrink();
                    return _PreviewCard(
                      titulo: _tituloCtrl.text,
                      descripcion: _descripcionCtrl.text,
                      categoriaNombre: _selectedCategoria?.nombre,
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Botón de envío ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_outlined, size: 20),
                      label: Text(
                        _isSubmitting ? 'Enviando…' : 'Enviar incidencia',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: CantillanaTheme.rojo,
                        disabledBackgroundColor:
                            CantillanaTheme.rojo.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: CantillanaTheme.dorado, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Campo título ────────────────────────────────────────────────────────
  Widget _buildTituloField() {
    return StatefulBuilder(
      builder: (_, setInner) => TextFormField(
        controller: _tituloCtrl,
        maxLength: _tituloMax,
        style: const TextStyle(color: Colors.white),
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setInner(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty)
            return 'El título no puede estar vacío';
          if (v.trim().length < 5)
            return 'El título debe tener al menos 5 caracteres';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Ej.: Farola rota en Calle Sevilla',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon:
              const Icon(Icons.title, color: CantillanaTheme.dorado, size: 20),
          counterStyle: TextStyle(
              color: CantillanaTheme.dorado.withOpacity(0.7), fontSize: 10),
          filled: true,
          fillColor: const Color(0xFF1B5E20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 3)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.rojo, width: 2)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.rojo, width: 3)),
          errorStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ── Grid de categorías ──────────────────────────────────────────────────
  Widget _buildCategoriaGrid(List<CategoriaModel> categorias) {
    final icons = {
      'Alumbrado': Icons.lightbulb_outline,
      'Limpieza': Icons.delete_outline,
      'Mobiliario': Icons.chair_outlined,
      'Viales': Icons.add_road,
      'Otros': Icons.category_outlined,
    };

    if (categorias.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
              color: CantillanaTheme.dorado, strokeWidth: 2));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categorias.map((cat) {
        final isSelected = _selectedCategoria?.id == cat.id;
        final icon = icons[cat.nombre] ?? Icons.help_outline;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategoria = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? CantillanaTheme.rojo : const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? CantillanaTheme.dorado : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: CantillanaTheme.rojo.withOpacity(0.25),
                          blurRadius: 8)
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white54),
                const SizedBox(width: 6),
                Text(
                  cat.nombre,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Campo descripción ────────────────────────────────────────────────────
  Widget _buildDescripcionField() {
    return StatefulBuilder(
      builder: (_, setInner) => TextFormField(
        controller: _descripcionCtrl,
        maxLength: _descMax,
        maxLines: 6,
        minLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setInner(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty)
            return 'La descripción no puede estar vacía';
          if (v.trim().length < 15)
            return 'Proporciona más detalles (mínimo 15 caracteres)';
          return null;
        },
        decoration: InputDecoration(
          hintText:
              'Describe la incidencia con detalle: ubicación exacta, cuándo ocurrió, impacto…',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          counterStyle: TextStyle(
              color: CantillanaTheme.dorado.withOpacity(0.7), fontSize: 10),
          filled: true,
          fillColor: const Color(0xFF1B5E20),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.dorado, width: 3)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.rojo, width: 2)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CantillanaTheme.rojo, width: 3)),
          errorStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: CantillanaTheme.dorado,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 7),
        Text(text,
            style: const TextStyle(
                color: CantillanaTheme.dorado,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Tarjeta de vista previa antes de enviar
class _PreviewCard extends StatelessWidget {
  final String titulo, descripcion;
  final String? categoriaNombre;

  const _PreviewCard(
      {required this.titulo, required this.descripcion, this.categoriaNombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4023),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_outlined,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              const Text('Vista previa',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              if (categoriaNombre != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CantillanaTheme.dorado.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: CantillanaTheme.dorado.withOpacity(0.4)),
                  ),
                  child: Text(categoriaNombre!,
                      style: const TextStyle(
                          color: CantillanaTheme.dorado,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (titulo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(descripcion,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CantillanaTheme.estadoPendiente.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: CantillanaTheme.estadoPendiente.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        size: 10, color: CantillanaTheme.estadoPendiente),
                    const SizedBox(width: 4),
                    Text('Pendiente',
                        style: TextStyle(
                            color: CantillanaTheme.estadoPendiente,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
