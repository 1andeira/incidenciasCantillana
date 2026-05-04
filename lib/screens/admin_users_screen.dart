// ─────────────────────────────────────────
// lib/screens/admin_users_screen.dart
// Gestión de usuarios — solo accesible para admins
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/services/supabase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _auth = Get.find<AuthController>();
  final _sb = SupabaseService.client;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Redirigir si el usuario actual no es admin
    if (!_auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return;
    }
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final rows = await _sb
          .from('usuarios')
          .select()
          .order('fecha_registro', ascending: false);
      setState(() {
        _users = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los usuarios: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(Map<String, dynamic> userRow) {
    final nombre = userRow['nombre'] as String? ?? 'Usuario';
    final id = userRow['id'] as String;

    // No permitir que el admin se elimine a sí mismo
    if (id == _auth.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('No puedes eliminar tu propia cuenta.'),
            ],
          ),
          backgroundColor: CantillanaTheme.rojo,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CantillanaTheme.verdeOscuro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CantillanaTheme.rojo, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: CantillanaTheme.rojo, size: 22),
            SizedBox(width: 8),
            Text('Eliminar usuario',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          '¿Seguro que quieres eliminar a "$nombre"?\n\nSus incidencias y comentarios permanecerán en el sistema.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(id);
            },
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(
              backgroundColor: CantillanaTheme.rojo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: CantillanaTheme.dorado),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String id) async {
    try {
      await _sb.from('usuarios').delete().eq('id', id);
      setState(() => _users.removeWhere((u) => u['id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: CantillanaTheme.dorado),
                SizedBox(width: 8),
                Text('Usuario eliminado correctamente'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al eliminar el usuario: $e',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: CantillanaTheme.rojo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: CantillanaTheme.dorado, strokeWidth: 2),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: CantillanaTheme.rojo),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                    backgroundColor: CantillanaTheme.rojo),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('No hay usuarios registrados.',
            style: TextStyle(color: Colors.white70)),
      );
    }

    final df = DateFormat('dd/MM/yyyy');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final u = _users[index];
        final uid = u['id'] as String;
        final nombre = u['nombre'] as String? ?? 'Sin nombre';
        final email = u['email'] as String?;
        final telefono = u['telefono'] as String?;
        final rol = u['rol'] as String? ?? 'usuario';
        final fechaStr = u['fecha_registro'] as String?;
        final fecha =
            fechaStr != null ? df.format(DateTime.parse(fechaStr)) : '—';
        final isCurrentUser = uid == _auth.userId;
        final isAdmin = rol == 'admin';

        final initials = () {
          final parts = nombre.trim().split(' ');
          if (parts.length >= 2) {
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
          return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
        }();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C32),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentUser
                  ? CantillanaTheme.dorado.withOpacity(0.5)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAdmin ? CantillanaTheme.rojo : const Color(0xFF0E4023),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAdmin
                        ? CantillanaTheme.dorado
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: CantillanaTheme.rojo.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      CantillanaTheme.rojo.withOpacity(0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 9, color: CantillanaTheme.rojo),
                                SizedBox(width: 3),
                                Text('Admin',
                                    style: TextStyle(
                                        color: CantillanaTheme.rojo,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        if (isCurrentUser)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: CantillanaTheme.dorado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: CantillanaTheme.dorado
                                      .withOpacity(0.5)),
                            ),
                            child: const Text('Tú',
                                style: TextStyle(
                                    color: CantillanaTheme.dorado,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (email != null)
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    if (telefono != null)
                      Text(telefono,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('Registrado: $fecha',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),

              // Botón eliminar (deshabilitado para uno mismo)
              if (!isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: CantillanaTheme.rojo, size: 20),
                  tooltip: 'Eliminar usuario',
                  onPressed: () => _confirmDelete(u),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        );
      },
    );
  }
}