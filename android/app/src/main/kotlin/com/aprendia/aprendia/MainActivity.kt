package com.aprendia.aprendia

import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val securityChannelName = "com.aprendia.aprendia/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: impide capturas de pantalla y grabaciones de la app.
        // El SO mostrará pantalla negra si el usuario intenta capturar.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAdbEnabled" -> {
                        val adbEnabled = Settings.Global.getInt(
                            contentResolver,
                            Settings.Global.ADB_ENABLED,
                            0
                        ) == 1
                        result.success(adbEnabled)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
