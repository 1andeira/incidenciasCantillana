plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Parsear dart-defines desde --dart-define-from-file
val dartDefines: Map<String, String> = run {
    val encoded = project.findProperty("dart-defines") as String? ?: return@run emptyMap()
    encoded.split(",").associate { entry ->
        val decoded = String(java.util.Base64.getDecoder().decode(entry)).split("=")
        if (decoded.size == 2) decoded[0] to decoded[1] else "" to ""
    }.filterKeys { it.isNotEmpty() }
}

android {
    namespace = "com.example.cantillana_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.cantillana_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = dartDefines["GOOGLE_MAPS_API_KEY"] ?: ""
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}