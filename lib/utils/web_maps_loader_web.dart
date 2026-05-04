// lib/utils/web_maps_loader_web.dart
// Inyecta el script de Google Maps JS API en el <head> del documento web.
// Solo se compila para la plataforma web (dart.library.html).

// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<void> injectGoogleMapsScript(String apiKey) async {
  // Si google.maps ya existe (script cargado previamente), salir.
  if (js.context.hasProperty('google')) return;

  final completer = Completer<void>();

  final script = html.ScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places'
    ..async = true
    ..defer = true;

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });

  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        Exception('No se pudo cargar la API de Google Maps para web.'),
      );
    }
  });

  html.document.head!.children.add(script);
  await completer.future;
}
