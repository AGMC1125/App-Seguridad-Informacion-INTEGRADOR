package com.aprendia.aprendia

import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Canal de comunicación Dart ↔ Kotlin para verificaciones RASP.
    // El nombre debe coincidir exactamente con el usado en Dart.
    private val SECURITY_CHANNEL = "com.aprendia.aprendia/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: impide capturas de pantalla y grabaciones de la app.
        // El SO mostrará pantalla negra si el usuario intenta capturar.
        // TODO: reactivar antes de subir a producción
        // window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registrar el MethodChannel para que Dart pueda consultar el estado
        // de Settings.Global.ADB_ENABLED directamente desde la API nativa.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isUsbDebuggingEnabled" -> {
                    // Settings.Global.ADB_ENABLED == 1 cuando USB Debugging
                    // está activo en Ajustes de desarrollador del dispositivo.
                    val adbEnabled = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.ADB_ENABLED,
                        0  // valor por defecto: desactivado
                    )
                    result.success(adbEnabled == 1)
                }
                else -> result.notImplemented()
            }
        }
    }
}
