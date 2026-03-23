// ─────────────────────────────────────────
// lib/screens/profile_screen.dart
// OPTIMIZADO - Colores del escudo sin redundancias
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/incidentModel.dart';
import 'package:cantillana_incidencias/models/userModel.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.currentUser.value;
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/login'),
        );
        return const SizedBox.shrink();
      }
      return _ProfileView(user: user, auth: auth);
    });
  }
}

class _ProfileView extends StatefulWidget {
  final UserModel user;
  final AuthController auth;

  const _ProfileView({required this.user, required this.auth});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isEditing = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CantillanaTheme.verdeOscuro,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: CantillanaTheme.rojo,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Editar perfil',
                  onPressed: () => setState(() => _isEditing = true),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cancelar',
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _nameCtrl.text = widget.user.name;
                    _phoneCtrl.text = widget.user.phone ?? '';
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  tooltip: 'Guardar',
                  onPressed: _saveProfile,
                ),
              ],
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () => _confirmLogout(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                user: widget.user,
                isEditing: _isEditing,
                nameCtrl: _nameCtrl,
                phoneCtrl: _phoneCtrl,
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: CantillanaTheme.dorado,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Mis Incidencias'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _SummaryTab(user: widget.user),
            _MyIncidentsTab(userId: widget.user.id),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    await widget.auth.updateProfile(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
    );
    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CantillanaTheme.verdeOscuro,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar la sesión?',
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
            onPressed: () async {
              Navigator.pop(context);
              await Get.find<AuthController>().logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Cabecera del perfil
// ─────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isEditing;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  const _ProfileHeader({
    required this.user,
    required this.isEditing,
    required this.nameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CantillanaTheme.rojo, CantillanaTheme.rojoOscuro],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: CantillanaTheme.dorado.withOpacity(0.3),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: CantillanaTheme.dorado,
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: CantillanaTheme.rojoOscuro,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (!isEditing) ...[
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CantillanaTheme.dorado.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CantillanaTheme.dorado,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ] else ...[
                _InlineField(controller: nameCtrl, hint: 'Nombre completo'),
                const SizedBox(height: 8),
                _InlineField(
                  controller: phoneCtrl,
                  hint: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InlineField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: CantillanaTheme.dorado, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: CantillanaTheme.dorado, width: 3),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// Tab Resumen
// ─────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final UserModel user;
  const _SummaryTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<IncidentController>();

    return Container(
      color: CantillanaTheme.verdeOscuro,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Mis estadísticas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CantillanaTheme.dorado,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final mine = ctrl.incidentsByUser(user.id);
            return Row(
              children: [
                _StatCard(
                  label: 'Total',
                  value: mine.length,
                  icon: Icons.assignment_outlined,
                  color: CantillanaTheme.rojo,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Pendientes',
                  value: mine
                      .where((i) => i.status == IncidentStatus.pending)
                      .length,
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Resueltas',
                  value: mine
                      .where((i) => i.status == IncidentStatus.resolved)
                      .length,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ],
            );
          }),
          const SizedBox(height: 28),

          Text(
            'Datos de la cuenta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CantillanaTheme.dorado,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          if (user.phone != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: user.phone!,
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Miembro desde',
            value: DateFormat('dd/MM/yyyy').format(user.createdAt),
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Rol',
            value: user.roleLabel,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: CantillanaTheme.dorado),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// Tab Mis Incidencias
// ─────────────────────────────────────────

class _MyIncidentsTab extends StatelessWidget {
  final String userId;
  const _MyIncidentsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<IncidentController>();

    return Container(
      color: CantillanaTheme.verdeOscuro,
      child: Obx(() {
        final mine = ctrl.incidentsByUser(userId);

        if (mine.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: CantillanaTheme.dorado.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aún no has reportado incidencias',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mine.length,
          itemBuilder: (context, i) => _CompactIncidentTile(incident: mine[i]),
        );
      }),
    );
  }
}

class _CompactIncidentTile extends StatelessWidget {
  final IncidentModel incident;
  const _CompactIncidentTile({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Color(0xFF1B5E20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: CantillanaTheme.dorado, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _statusColor(incident.status).withOpacity(0.3),
          child: Icon(
            _statusIcon(incident.status),
            color: _statusColor(incident.status),
            size: 20,
          ),
        ),
        title: Text(
          incident.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              incident.category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: CantillanaTheme.dorado,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(incident.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            incident.statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => context.push('/incident/${incident.id}'),
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
}
