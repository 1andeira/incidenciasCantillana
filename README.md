



# Cantillana Incidencias

Aplicación móvil para la gestión de incidencias municipales del **Ayuntamiento de Cantillana**.  
Permite a los ciudadanos reportar incidencias, adjuntar imágenes y geolocalización, y hacer seguimiento de su estado.

---

## 🛠️ Stack tecnológico

| Capa                     | Tecnología                          | Versión                       |
| ------------------------ | ----------------------------------- | ----------------------------- |
| **Lenguaje / SDK**       | Dart (Flutter SDK)                  | Flutter 3.38.1 / Dart ≥ 3.3.0 |
| **JDK (Android build)**  | Eclipse Temurin JDK                 | 17.0.18+8                     |
| **Estado reactivo**      | GetX                                | ^4.6.6                        |
| **Navegación**           | go_router                           | ^14.2.7                       |
| **Mapas**                | google_maps_flutter                 | ^2.17.0                       |
| **Geolocalización**      | geolocator                          | ^14.0.2                       |
| **Imágenes**             | image_picker + cached_network_image | ^1.0.0 / ^3.2.0               |
| **Permisos**             | permission_handler                  | ^11.4.0                       |
| **Internacionalización** | intl                                | ^0.19.0                       |
| **Iconos**               | cupertino_icons                     | ^1.0.8                        |
| **Launcher**             | url_launcher                        | ^6.3.2                        |
| **Linting**              | flutter_lints                       | ^4.0.0                        |

---

## 📍 Geolocalización (`geolocator`)

La dependencia [`geolocator ^14.0.2`](https://pub.dev/packages/geolocator) proporciona acceso a la posición GPS/red del dispositivo y se integra con el flujo de reporte de incidencias.

### ¿Qué hace?

| Responsabilidad                  | Detalle                                                                                                                                                          |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Solicitud de permisos**        | Comprueba y solicita `LocationPermission` en tiempo de ejecución (Android `ACCESS_FINE_LOCATION`, iOS `NSLocationWhenInUseUsageDescription`)                     |
| **Obtención de posición**        | Llama a `Geolocator.getCurrentPosition()` con precisión alta (`LocationAccuracy.high`) para obtener latitud y longitud del dispositivo                           |
| **Centrado automático del mapa** | La posición obtenida se usa para centrar la cámara de `GoogleMap` en `MapPickerScreen`, evitando que el usuario tenga que navegar manualmente hasta su ubicación |
| **Validación municipal**         | Las coordenadas devueltas se validan contra los límites del término municipal de Cantillana antes de aceptarlas                                                  |
| **Fallback**                     | Si el permiso es denegado o el GPS no está disponible, el mapa se centra en las coordenadas por defecto de Cantillana (`37.5997, -5.5936`)                       |

### Flujo de uso

```
Usuario toca "Mi ubicación"
        │
        ▼
Geolocator.checkPermission()
        │
   ┌────┴────┐
denied     granted
   │           │
Solicitar   getCurrentPosition(accuracy: high)
permiso          │
   │         LatLng obtenida
   │             │
   └─────────────┤
                 ▼
        MapPickerScreen centra
        cámara en la posición
        y valida municipio
```

### Permisos requeridos

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para registrar la incidencia correctamente.</string>
```

---

## 📋 Requisitos previos

| Herramienta        | Versión requerida                                   | Enlace                                                        |
| ------------------ | --------------------------------------------------- | ------------------------------------------------------------- |
| **Flutter SDK**    | 3.38.1                                              | [flutter.dev](https://docs.flutter.dev/get-started/install)   |
| **JDK**            | Eclipse Temurin **17.0.18+8**                       | [adoptium.net](https://adoptium.net/)                         |
| **Gradle**         | **8.14** (gestionado por el wrapper del proyecto)   | —                                                             |
| **Android Studio** | Cualquier versión reciente con emulador configurado | [developer.android.com](https://developer.android.com/studio) |
| **Google Cloud**   | Maps SDK for Android/iOS habilitada                 | [console.cloud.google.com](https://console.cloud.google.com/) |

> [!IMPORTANT]
> El proyecto **no es compatible con Java 21 ni superior**. Gradle 8.14 requiere estrictamente **JDK 17**. Usar otra versión provocará errores de compilación en el build de Android.

---

## 🚀 Puesta en marcha

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Configurar el JDK 17 antes de compilar

Es imprescindible que `JAVA_HOME` apunte a la instalación de **Eclipse Temurin JDK 17.0.18+8**.  
Ajusta la ruta a donde hayas instalado el JDK en tu máquina:

**Windows (PowerShell):**

```powershell
$env:JAVA_HOME = "<ruta-a-tu-instalación-de-jdk-17>"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

**macOS / Linux:**

```bash
export JAVA_HOME=<ruta-a-tu-instalación-de-jdk-17>
export PATH="$JAVA_HOME/bin:$PATH"
```

Verifica que la configuración es correcta:

```bash
java -version
# Debe mostrar: openjdk 17.0.18 ... Eclipse Adoptium
```

### 3. Lanzar el emulador Android

```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar el emulador (sustituye el nombre por el de tu AVD)
flutter emulators --launch <nombre-del-avd>
```

Espera 30–60 segundos hasta que el emulador esté completamente iniciado.

### 4. Ejecutar la aplicación

```bash
flutter run
```

### 5. Compilar APK release

```bash
flutter build apk --release
```

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart
├── router/          # go_router – rutas declarativas
├── models/          # Modelos de datos (IncidentModel, etc.)
├── screens/         # Pantallas (ciudadano, detalle de incidencia…)
└── assets/
    └── cantillan.png
```

---

## 📄 Licencia

Proyecto interno del Ayuntamiento de Cantillana. Todos los derechos reservados.
