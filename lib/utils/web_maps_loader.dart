// lib/utils/web_maps_loader.dart
// Exporta la implementación correcta según la plataforma:
//  • dart.library.html  → web  (web_maps_loader_web.dart)
//  • resto              → stub (web_maps_loader_stub.dart)

export 'web_maps_loader_stub.dart'
    if (dart.library.html) 'web_maps_loader_web.dart';
