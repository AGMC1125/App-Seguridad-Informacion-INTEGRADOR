package com.aprendia.aprendia

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: impide capturas de pantalla y grabaciones de la app.
        // El SO mostrará pantalla negra si el usuario intenta capturar.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
