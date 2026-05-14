// ─────────────────────────────────────────
// lib/screens/create_incident_screen.dart
// Formulario de nueva incidencia — con soporte de ubicación en WEB y móvil
// ─────────────────────────────────────────

import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/controllers/AuthController.dart';
import 'package:cantillana_incidencias/controllers/IncidentController.dart';
import 'package:cantillana_incidencias/models/categoriaModel.dart';
import 'package:cantillana_incidencias/models/ubicacionModel.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cantillana_incidencias/screens/map_picker_screen.dart';

// permission_handler solo existe en móvil — se importa condicionalmente
// mediante una guardia kIsWeb en tiempo de ejecución.
import 'package:permission_handler/permission_handler.dart';

// ─── IMPORTANTE ───────────────────────────────────────────────────────────────
// Para que Google Maps funcione en la versión WEB debes añadir en
// web/index.html, dentro de <head>, antes del cierre </head>:
//
//   <script src="https://maps.googleapis.com/maps/api/js?key=TU_API_KEY"></script>
//
// Y en pubspec.yaml asegúrate de tener:
//   google_maps_flutter: ^2.x.x          (ya lo tienes)
//   google_maps_flutter_web: ^0.5.x       (añádelo si no está)
// ─────────────────────────────────────────────────────────────────────────────

// ── Clave de API para Static Maps (web preview) ───────────────────────────────
// Puedes reutilizar la misma clave de Maps JS; asegúrate de que la API
// "Maps Static API" esté habilitada en tu proyecto de Google Cloud.
const String _kStaticMapsApiKey = 'TU_API_KEY_AQUI';

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
  UbicacionModel? _ubicacion;
  bool _isSubmitting = false;

  List<XFile> _selectedImages = [];

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const int _tituloMax = 80;
  static const int _descMax = 500;

  // Límites del término municipal de Cantillana
  static const LatLng _swBound = LatLng(37.570, -5.870);
  static const LatLng _neBound = LatLng(37.660, -5.760);

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
    _ctrl.clearPendingImages();
    super.dispose();
  }

  // ── Selector de ubicación ─────────────────────────────────────────────────

  Future<void> _abrirMapPicker() async {
    final result = await Navigator.of(context).push<UbicacionModel?>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initialUbicacion: _ubicacion),
        fullscreenDialog: true,
      ),
    );
    if (result != null) setState(() => _ubicacion = result);
  }

  Future<void> _usarUbicacionActual() async {
    try {
      // ── Verificar servicio GPS/geolocalización ──────────────────────────
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(kIsWeb
            ? 'Permite el acceso a la ubicación en tu navegador.'
            : 'Activa el GPS del dispositivo.');
        return;
      }

      // ── Permisos: permission_handler solo en móvil ──────────────────────
      // En web el navegador gestiona el permiso a través de Geolocator
      // directamente (no existe permission_handler en web).
      if (!kIsWeb) {
        final status = await Permission.locationWhenInUse.request();
        if (status.isDenied || status.isPermanentlyDenied) return;
      }

      // ── Obtener posición ────────────────────────────────────────────────
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // ── Validar que está dentro de Cantillana ───────────────────────────
      if (position.latitude < _swBound.latitude ||
          position.latitude > _neBound.latitude ||
          position.longitude < _swBound.longitude ||
          position.longitude > _neBound.longitude) {
        _showError(
            'Tu ubicación está fuera del término municipal de Cantillana.');
        return;
      }

      setState(() => _ubicacion = UbicacionModel(
            latitud: position.latitude,
            longitud: position.longitude,
          ));
    } catch (e) {
      _showError('No se pudo obtener la ubicación.');
    }
  }

  void _quitarUbicacion() => setState(() => _ubicacion = null);

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoria == null) {
      _showError('Selecciona una categoría para continuar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final incident = await _ctrl.createIncident(
        categoriaId: _selectedCategoria!.id,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        latitud: _ubicacion?.latitud,
        longitud: _ubicacion?.longitud,
        descripcionDireccion: _ubicacion?.descripcionDireccion,
      );

      if (incident == null) {
        _showError('No se pudo crear la incidencia.');
        return;
      }

      if (!mounted) return;
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

      context.go('/incident/${incident.id}');
    } catch (e) {
      _showError('Error al crear la incidencia: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        backgroundColor: CantillanaTheme.rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // ── Info ───────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CantillanaTheme.dorado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: CantillanaTheme.dorado.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: CantillanaTheme.dorado, size: 20),
                        SizedBox(width: 10),
                        Expanded(
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

                  // ── Título ─────────────────────────────────────────────
                  _SectionLabel(text: 'Título de la incidencia *'),
                  const SizedBox(height: 8),
                  _buildTituloField(),

                  const SizedBox(height: 20),

                  // ── Categoría ──────────────────────────────────────────
                  _SectionLabel(text: 'Categoría *'),
                  const SizedBox(height: 8),
                  Obx(() => _buildCategoriaGrid(_ctrl.categorias)),

                  const SizedBox(height: 20),

                  // ── Descripción ────────────────────────────────────────
                  _SectionLabel(text: 'Descripción *'),
                  const SizedBox(height: 8),
                  _buildDescripcionField(),

                  const SizedBox(height: 24),

                  // ── Ubicación: disponible en web Y móvil ──────────────
                  _SectionLabel(text: 'Ubicación en Cantillana (opcional)'),
                  const SizedBox(height: 8),
                  _buildUbicacionWidget(),
                  const SizedBox(height: 24),

                  // ── Imágenes ───────────────────────────────────────────
                  _SectionLabel(text: 'Imágenes (opcional)'),
                  const SizedBox(height: 8),
                  _buildImagePickerButtons(),

                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImagePreviewGallery(),
                  ],

                  const SizedBox(height: 28),

                  // ── Vista previa ───────────────────────────────────────
                  Builder(builder: (context) {
                    final hasData = _tituloCtrl.text.isNotEmpty ||
                        _descripcionCtrl.text.isNotEmpty ||
                        _selectedCategoria != null;
                    if (!hasData) return const SizedBox.shrink();
                    return _PreviewCard(
                      titulo: _tituloCtrl.text,
                      descripcion: _descripcionCtrl.text,
                      categoriaNombre: _selectedCategoria?.nombre,
                      ubicacion: _ubicacion,
                    );
                  }),

                  const SizedBox(height: 16),

                  // ── Enviar ─────────────────────────────────────────────
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

  // ── Widget de ubicación (web + móvil) ─────────────────────────────────────

  Widget _buildUbicacionWidget() {
    if (_ubicacion == null) {
      return Column(
        children: [
          // Botón "Marcar en el mapa"
          GestureDetector(
            onTap: _abrirMapPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CantillanaTheme.dorado, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt_outlined,
                      color: CantillanaTheme.dorado, size: 22),
                  SizedBox(width: 10),
                  Text('Marcar en el mapa',
                      style: TextStyle(
                          color: CantillanaTheme.dorado,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Botón "Usar ubicación actual"
          GestureDetector(
            onTap: _usarUbicacionActual,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    kIsWeb
                        ? 'Usar mi ubicación (navegador)'
                        : 'Usar ubicación actual',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ── Vista previa del mapa cuando hay ubicación seleccionada ────────────
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CantillanaTheme.dorado, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: kIsWeb
                ? _buildStaticMapPreview(
                    lat: _ubicacion!.latitud,
                    lng: _ubicacion!.longitud,
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_ubicacion!.latitud, _ubicacion!.longitud),
                      zoom: 16.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('preview'),
                        position:
                            LatLng(_ubicacion!.latitud, _ubicacion!.longitud),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                      ),
                    },
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    liteModeEnabled: true,
                  ),
          ),
          Container(
            color: const Color(0xFF0E4023),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.pin_drop,
                    size: 14, color: CantillanaTheme.dorado),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _ubicacion!.coordenadasLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _abrirMapPicker,
                  icon: const Icon(Icons.edit_location_alt,
                      size: 15, color: CantillanaTheme.dorado),
                  label: const Text('Cambiar',
                      style: TextStyle(
                          color: CantillanaTheme.dorado,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _quitarUbicacion,
                  child:
                      const Icon(Icons.close, size: 18, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Static Maps preview (solo web) ───────────────────────────────────────
  Widget _buildStaticMapPreview({
    required double lat,
    required double lng,
    int zoom = 16,
    int width = 600,
    int height = 320,
  }) {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      {
        'center': '$lat,$lng',
        'zoom': '$zoom',
        'size': '${width}x$height',
        'scale': '2',
        'maptype': 'roadmap',
        'markers': 'color:red|$lat,$lng',
        'key': _kStaticMapsApiKey,
      },
    ).toString();

    return Image.network(
      url,
      width: double.infinity,
      height: 160,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF0E4023),
          child: const Center(
            child: CircularProgressIndicator(
              color: CantillanaTheme.dorado,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF0E4023),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined,
                  color: CantillanaTheme.dorado, size: 32),
              const SizedBox(height: 8),
              Text(
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Vista de mapa no disponible',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Campo título ──────────────────────────────────────────────────────────

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

  // ── Grid categorías ───────────────────────────────────────────────────────

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

  // ── Campo descripción ─────────────────────────────────────────────────────

  Widget _buildDescripcionField() {
    return StatefulBuilder(
      builder: (_, setInner) => TextFormField(
        controller: _descripcionCtrl,
        maxLength: _descMax,
        // FIX: overflow no es parámetro de TextField, se eliminó
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

  // ── Botones de imagen ─────────────────────────────────────────────────────

  Widget _buildImagePickerButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _ctrl.pickImagesFromGallery();
              setState(() => _selectedImages = List.from(_ctrl.pendingImages));
            },
            icon: const Icon(Icons.image_outlined, size: 18),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CantillanaTheme.dorado,
              side: const BorderSide(color: CantillanaTheme.dorado, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (!kIsWeb)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await _ctrl.pickImageFromCamera();
                setState(
                    () => _selectedImages = List.from(_ctrl.pendingImages));
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Cámara'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CantillanaTheme.dorado,
                side: const BorderSide(color: CantillanaTheme.dorado, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  // ── Preview de imágenes ───────────────────────────────────────────────────

  Widget _buildImagePreviewGallery() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(Icons.image_outlined, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text('${_selectedImages.length} imagen(es)',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final xfile = _selectedImages[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                xfile.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : Image.file(
                                File(xfile.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                            _ctrl.removeImage(xfile.path);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: CantillanaTheme.rojo.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 100,
        height: 100,
        color: Colors.white10,
        child: const Icon(Icons.image_not_supported, color: Colors.white30),
      );
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

class _PreviewCard extends StatelessWidget {
  final String titulo, descripcion;
  final String? categoriaNombre;
  final UbicacionModel? ubicacion;

  const _PreviewCard({
    required this.titulo,
    required this.descripcion,
    this.categoriaNombre,
    this.ubicacion,
  });

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
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
              if (ubicacion != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CantillanaTheme.dorado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: CantillanaTheme.dorado.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 10, color: CantillanaTheme.dorado),
                      SizedBox(width: 4),
                      Text('Con ubicación',
                          style: TextStyle(
                              color: CantillanaTheme.dorado,
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
