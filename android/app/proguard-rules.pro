# =============================================================================
#  AprendIA — Reglas ProGuard / R8
#  Proyecto: AprendIA (LSM - Lengua de Señas Mexicana)
#  Estas reglas indican a R8 qué clases/métodos NO deben ser renombrados
#  o eliminados, ya que son accedidos por reflexión, por el sistema Android
#  o por frameworks externos que dependen de los nombres en tiempo de ejecución.
# =============================================================================


# ── 1. FLUTTER ENGINE ────────────────────────────────────────────────────────
# El motor de Flutter accede a estas clases por reflexión desde C++ (embedding).
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.**


# ── 2. FIREBASE CORE & CLOUD MESSAGING (FCM) ─────────────────────────────────
# Firebase registra sus clases en el AndroidManifest y las instancia
# por nombre en tiempo de ejecución mediante el sistema de servicios de Android.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# FirebaseMessagingService y su receptor deben conservar su nombre exacto.
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class com.google.firebase.iid.** { *; }

# Clases de la app que extienden FirebaseMessagingService
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }


# ── 3. FLUTTER LOCAL NOTIFICATIONS ───────────────────────────────────────────
# Los BroadcastReceivers de notificaciones son invocados por el SO por nombre.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**


# ── 4. ENCRYPT (AES-256 / Bouncy Castle) ─────────────────────────────────────
# La librería `encrypt` de Dart usa el plugin de Bouncy Castle en Android.
# Bouncy Castle registra sus proveedores mediante reflexión (Security.addProvider).
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }


# ── 5. GEOLOCATOR ────────────────────────────────────────────────────────────
# El plugin geolocator registra su canal de plataforma por nombre de clase.
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**


# ── 6. SHARED PREFERENCES ────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**


# ── 7. HTTP (dart:io HttpClient / OkHttp subyacente) ─────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }


# ── 8. PROVIDER (state management) ───────────────────────────────────────────
# Provider es Dart puro; sus clases Java/Kotlin no necesitan reglas especiales.
# Se incluye por completitud en caso de versiones que usen reflexión.
-keep class dev.flutter.plugins.** { *; }


# ── 9. CLASES PROPIAS DE LA APP ───────────────────────────────────────────────
# Mantener el nombre de la MainActivity (requerido por el sistema Android).
-keep class com.aprendia.aprendia.MainActivity { *; }

# Mantener el nombre de la Application class si existe.
-keep class com.aprendia.aprendia.** extends android.app.Application { *; }


# ── 10. REFLEXIÓN Y SERIALIZACIÓN GENERAL ────────────────────────────────────
# Preservar anotaciones en tiempo de ejecución (usadas por algunos frameworks).
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable

# Preservar clases de excepciones para que los stack traces sean legibles
# con los archivos de símbolos generados por --split-debug-info.
-keepattributes StackMap,StackMapTable


# ── 11. SUPPRESS WARNINGS DE LIBRERÍAS EXTERNAS ──────────────────────────────
-dontwarn javax.annotation.**
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn kotlin.**
-dontwarn kotlinx.**


# ── 12. NOTA SOBRE DEPURACIÓN POST-OFUSCACIÓN ────────────────────────────────
# Los stack traces del APK ofuscado se pueden descifrar con:
#   flutter symbolize -i <stack_trace_file> -d build/debug-info/<archivo>.symbols
# Los archivos en build/debug-info/ deben guardarse junto a cada release.
