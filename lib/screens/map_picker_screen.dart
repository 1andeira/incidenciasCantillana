// ─────────────────────────────────────────
// lib/screens/map_picker_screen.dart
// Selector de ubicación restringido al
// término municipal de Cantillana (Sevilla)
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/models/ubicacionModel.dart';

/// Límites aproximados del término municipal de Cantillana.
/// El mapa no permite al usuario salir de esta área.
const _cantillanaSW = LatLng(37.570, -5.650);
const _cantillanaNE = LatLng(37.640, -5.530);
const _cantillanaCenter = LatLng(37.5997, -5.5936);
const _defaultZoom = 14.0;
const _minZoom = 12.0; // No se puede alejar más de esto

class MapPickerScreen extends StatefulWidget {
  /// Si ya existe una ubicación previa, se muestra el pin en esa posición.
  final UbicacionModel? initialUbicacion;

  const MapPickerScreen({super.key, this.initialUbicacion});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;

  // Bounds para CameraTargetBounds y validación de toques
  static final _bounds = LatLngBounds(
    southwest: _cantillanaSW,
    northeast: _cantillanaNE,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialUbicacion != null) {
      _selectedLatLng = LatLng(
        widget.initialUbicacion!.latitud,
        widget.initialUbicacion!.longitud,
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  /// Valida que el punto tocado esté dentro del municipio.
  bool _dentroDeCantillana(LatLng punto) =>
      punto.latitude >= _cantillanaSW.latitude &&
      punto.latitude <= _cantillanaNE.latitude &&
      punto.longitude >= _cantillanaSW.longitude &&
      punto.longitude <= _cantillanaNE.longitude;

  void _onMapTap(LatLng position) {
    if (!_dentroDeCantillana(position)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: CantillanaTheme.dorado, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La ubicación debe estar dentro del término municipal de Cantillana.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: CantillanaTheme.verdeOscuro,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _selectedLatLng = position);
  }

  void _confirmar() {
    if (_selectedLatLng == null) return;
    final ubicacion = UbicacionModel(
      latitud: _selectedLatLng!.latitude,
      longitud: _selectedLatLng!.longitude,
    );
    Navigator.of(context).pop(ubicacion);
  }

  void _centrarEnCantillana() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_cantillanaCenter, _defaultZoom),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {};
    if (_selectedLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('incidencia'),
          position: _selectedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Ubicación de la incidencia'),
        ),
      );
    }

    return Scaffold(
      // ── AppBar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          if (_selectedLatLng != null)
            TextButton.icon(
              onPressed: _confirmar,
              icon: const Icon(Icons.check, color: CantillanaTheme.dorado),
              label: const Text(
                'Confirmar',
                style: TextStyle(
                  color: CantillanaTheme.dorado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),

      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng ?? _cantillanaCenter,
              zoom: _defaultZoom,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Aplica estilo oscuro acorde al tema de la app
              controller.setMapStyle(_darkMapStyle);
            },
            onTap: _onMapTap,
            markers: markers,
            minMaxZoomPreference: const MinMaxZoomPreference(_minZoom, 19.0),
            cameraTargetBounds: CameraTargetBounds(_bounds),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Indicador de instrucción (top) ──────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: CantillanaTheme.verdeOscuro.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CantillanaTheme.dorado, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app,
                      color: CantillanaTheme.dorado, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Toca el mapa para marcar la ubicación exacta de la incidencia.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Controles flotantes (derecha) ───────────────────────────────
          Positioned(
            right: 12,
            bottom: _selectedLatLng != null ? 120 : 24,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.add,
                  tooltip: 'Acercar',
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icons.remove,
                  tooltip: 'Alejar',
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icons.location_city,
                  tooltip: 'Centrar en Cantillana',
                  onTap: _centrarEnCantillana,
                ),
              ],
            ),
          ),

          // ── Panel inferior con coordenadas ──────────────────────────────
          if (_selectedLatLng != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                decoration: BoxDecoration(
                  color: CantillanaTheme.verdeOscuro,
                  border: const Border(
                    top: BorderSide(color: CantillanaTheme.dorado, width: 2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                          color: CantillanaTheme.dorado,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 5),
                        Text(
                          '${_selectedLatLng!.latitude.toStringAsFixed(5)}, '
                          '${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _selectedLatLng = null),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Quitar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _confirmar,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text(
                              'Confirmar ubicación',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: CantillanaTheme.rojo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                    color: CantillanaTheme.dorado),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Botón flotante del mapa
// ─────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CantillanaTheme.verdeOscuro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CantillanaTheme.dorado, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Estilo oscuro para el mapa (acorde al tema)
// ─────────────────────────────────────────
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c1d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec38e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3320"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2e5e2e"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64835e"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#233b23"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#8aa88a"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1e3d1e"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b8f6b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2d4f2d"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1f3a1f"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#c8a44a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d6b3d"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#2a4d2a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#c8a44a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#243d24"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#b8c8b8"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d2b0d"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e7e4e"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17300a"}]}
]
''';
