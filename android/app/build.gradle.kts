plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.aprendia.aprendia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aprendia.aprendia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // Firebase requiere mínimo 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing con debug keys para pruebas de release local.
            signingConfig = signingConfigs.getByName("debug")

            // ── R8: Ofuscación, Shrinking y Optimización ──────────────────
            // isMinifyEnabled activa R8 (sucesor de ProGuard) que realiza:
            //   1. Shrinking  → elimina clases/métodos no utilizados.
            //   2. Obfuscation → renombra clases, métodos y variables.
            //   3. Optimization → simplifica y optimiza el bytecode.
            isMinifyEnabled = true

            // Elimina recursos (imágenes, layouts, strings) no referenciados.
            isShrinkResources = true

            proguardFiles(
                // Reglas base optimizadas de Android para producción.
                getDefaultProguardFile("proguard-android-optimize.txt"),
                // Reglas personalizadas del proyecto (Firebase, Flutter, etc.).
                "proguard-rules.pro"
            )
        }

        debug {
            // En debug NO se activa R8 para facilitar el desarrollo.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
