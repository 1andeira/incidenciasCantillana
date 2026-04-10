// ─────────────────────────────────────────
// lib/screens/map_picker_screen.dart
// Selector de ubicación restringido al
// término municipal de Cantillana (Sevilla)
// Con marcador de ubicación actual
// ─────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:cantillana_incidencias/config/CantillanaTheme.dart';
import 'package:cantillana_incidencias/models/ubicacionModel.dart';

const _cantillanaSW = LatLng(37.570, -5.870);
const _cantillanaNE = LatLng(37.660, -5.760);
const _cantillanaCenter = LatLng(37.6109, -5.8235);
const _defaultZoom = 15.0;
const _minZoom = 13.0;

class MapPickerScreen extends StatefulWidget {
  final UbicacionModel? initialUbicacion;

  const MapPickerScreen({super.key, this.initialUbicacion});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  LatLng? _userLocation;
  bool _isLoadingLocation = true;

  static final _bounds = LatLngBounds(
    southwest: _cantillanaSW,
    northeast: _cantillanaNE,
  );

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.initialUbicacion != null) {
      _selectedLatLng = LatLng(
        widget.initialUbicacion!.latitud,
        widget.initialUbicacion!.longitud,
      );
    }
    _obtenerUbicacionActual();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final ubicacion = LatLng(position.latitude, position.longitude);

      if (_dentroDeCantillana(ubicacion)) {
        if (mounted) {
          setState(() {
            _userLocation = ubicacion;
            _isLoadingLocation = false;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(ubicacion, _defaultZoom),
          );
        }
      } else {
        if (mounted) setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

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

  void _centrarEnUbicacionActual() {
    if (_userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, _defaultZoom),
      );
    }
  }

  Set<Marker> _construirMarcadores() {
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

    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ubicacion_actual'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Tu ubicación actual'),
        ),
      );
    }

    return markers;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final target = _selectedLatLng ?? _cantillanaCenter;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(target, _defaultZoom),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _cantillanaCenter,
              zoom: _defaultZoom,
            ),
            onMapCreated: _onMapCreated,
            onTap: _onMapTap,
            markers: _construirMarcadores(),
            minMaxZoomPreference: const MinMaxZoomPreference(_minZoom, 19.0),
            cameraTargetBounds: CameraTargetBounds(_bounds),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Instrucción (top)
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
              child: const Row(
                children: [
                  Icon(Icons.touch_app,
                      color: CantillanaTheme.dorado, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toca el mapa para marcar la ubicación exacta de la incidencia.\n🔴 Rojo: Incidencia • 🟢 Verde: Tu ubicación',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles flotantes (derecha)
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
                const SizedBox(height: 8),
                if (_userLocation != null)
                  _MapFab(
                    icon: Icons.my_location,
                    tooltip: 'Mi ubicación',
                    onTap: _centrarEnUbicacionActual,
                  ),
              ],
            ),
          ),

          // Panel inferior con coordenadas
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
            boxShadow: const [
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
