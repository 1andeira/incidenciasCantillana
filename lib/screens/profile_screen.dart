// ─────────────────────────────────────────
// lib/screens/profile_screen.dart
// Perfil del usuario autenticado
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = Get.find<AuthController>();
  late final IncidentController _ctrl;

  // Campos de edición
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<IncidentController>();
    _resetForm();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    final user = _auth.user;
    _nombreCtrl.text = user?.nombre ?? '';
    _telefonoCtrl.text = user?.telefono ?? '';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _auth.updateProfile(
      nombre: _nombreCtrl.text,
      telefono: _telefonoCtrl.text.isNotEmpty ? _telefonoCtrl.text : null,
    );
    setState(() => _editMode = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: CantillanaTheme.dorado),
              SizedBox(width: 8),
              Text('Perfil actualizado correctamente'),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.logout();
              if (mounted) context.go('/login');
            },
            style:
                FilledButton.styleFrom(backgroundColor: CantillanaTheme.rojo),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Color _colorEstado(IncidentEstado e) => switch (e) {
        IncidentEstado.pendiente => CantillanaTheme.estadoPendiente,
        IncidentEstado.en_proceso => CantillanaTheme.estadoEnProceso,
        IncidentEstado.resuelta => CantillanaTheme.estadoResuelta,
        IncidentEstado.rechazada => CantillanaTheme.estadoRechazada,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (_editMode) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar',
              onPressed: () {
                setState(() => _editMode = false);
                _resetForm();
              },
            ),
            Obx(() => _auth.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Guardar',
                    onPressed: _save,
                  )),
          ] else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () => setState(() => _editMode = true),
            ),
        ],
      ),
      body: Obx(() {
        final user = _auth.user;
        if (user == null) {
          return const Center(
              child: Text('No hay sesión activa',
                  style: TextStyle(color: Colors.white70)));
        }

        final myIncidents = _ctrl.incidentsByUser(user.id);
        final df = DateFormat('dd/MM/yyyy');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar y datos básicos ─────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: CantillanaTheme.rojo,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: CantillanaTheme.dorado, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: CantillanaTheme.rojo.withOpacity(0.3),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_editMode) ...[
                        Text(
                          user.nombre,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.contacto,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Miembro desde ${df.format(user.fechaRegistro)}',
                          style: TextStyle(
                              color: CantillanaTheme.dorado.withOpacity(0.7),
                              fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Formulario de edición ──────────────────────────────────
                if (_editMode) ...[
                  const _SectionTitle(title: 'Editar datos'),
                  const SizedBox(height: 12),
                  _ProfileField(
                    controller: _nombreCtrl,
                    label: 'Nombre completo',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre no puede estar vacío'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono (opcional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 4),
                  // Email (solo lectura si existe)
                  if (user.email != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: Colors.white38, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                              Text(user.email!,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.lock_outline,
                              size: 14, color: Colors.white24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('  El email no se puede modificar.',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _auth.isLoading ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: CantillanaTheme.rojo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: CantillanaTheme.dorado, width: 2),
                        ),
                      ),
                      child: _auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar cambios',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Info del usuario (modo lectura) ────────────────────────
                if (!_editMode) ...[
                  _SectionTitle(title: 'Información de contacto'),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'ID de usuario',
                      value: '#${user.id}'),
                  if (user.email != null)
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email!),
                  if (user.telefono != null)
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: user.telefono!),
                  _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Fecha de registro',
                      value: df.format(user.fechaRegistro)),
                  const SizedBox(height: 28),
                ],

                // ── Mis incidencias ────────────────────────────────────────
                _SectionTitle(title: 'Mis incidencias (${myIncidents.length})'),
                const SizedBox(height: 12),
                if (myIncidents.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Text('Aún no has creado ninguna incidencia.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 13)),
                    ),
                  )
                else
                  ...myIncidents.take(5).map((inc) {
                    final color = _colorEstado(inc.estado);
                    return GestureDetector(
                      onTap: () => context.go('/incident/${inc.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C32),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border(left: BorderSide(color: color, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inc.titulo,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(inc.fechaCreacion),
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: color.withOpacity(0.5)),
                              ),
                              child: Text(inc.estadoLabel,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right,
                                size: 16, color: Colors.white38),
                          ],
                        ),
                      ),
                    );
                  }),

                if (myIncidents.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          final ctrl = Get.find<IncidentController>();
                          ctrl.onlyMine(true);
                          context.go('/');
                        },
                        child: Text(
                          'Ver todas (${myIncidents.length})',
                          style: TextStyle(
                              color: CantillanaTheme.dorado, fontSize: 13),
                        ),
                      ),
                    ),
                  ),

const SizedBox(height: 32),

                // ── Panel de administración (solo admin) ───────────────────
                Obx(() {
                  if (!_auth.isAdmin) return const SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () => context.go('/admin/users'),
                          icon: const Icon(Icons.manage_accounts, size: 18),
                          label: const Text('Gestionar usuarios'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0E4023),
                            foregroundColor: CantillanaTheme.dorado,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: CantillanaTheme.dorado, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

                // ── Cerrar sesión ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CantillanaTheme.rojo,
                      side: const BorderSide(
                          color: CantillanaTheme.rojo, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: CantillanaTheme.dorado,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: CantillanaTheme.dorado,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A5C32),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CantillanaTheme.dorado),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: CantillanaTheme.dorado, size: 20),
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
    );
  }
}
