import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('VirtualSign LSM — Política de Privacidad'),
            _meta('Desarrollador: KitsuneDev'),
            _meta('Última actualización: 26 de junio de 2026'),
            const SizedBox(height: 16),
            _body(
              'Esta Política de Privacidad describe cómo VirtualSign LSM recopila, '
              'usa y protege la información de sus usuarios. Al utilizar la '
              'aplicación, aceptas los términos descritos en este documento.',
            ),
            const SizedBox(height: 24),
            _heading('1. Información que recopilamos'),
            _bullet('Correo electrónico y contraseña',
                'Necesarios para crear una cuenta e iniciar sesión.'),
            _bullet('Texto ingresado por el usuario',
                'El texto que introduces para generar las señas en LSM. Se envía al servidor únicamente para procesar la solicitud y no se almacena de forma permanente.'),
            _bullet('Ubicación geográfica',
                'Se solicita acceso a la ubicación del dispositivo para funciones contextuales. No se comparte con terceros.'),
            _bullet('Token de dispositivo (Firebase)',
                'Se utiliza exclusivamente para el envío de notificaciones push.'),
            const SizedBox(height: 20),
            _heading('2. Cómo usamos la información'),
            _bullet('Autenticación',
                'Para autenticar al usuario mediante JWT (JSON Web Tokens).'),
            _bullet('Generación de señas',
                'Para generar videos de Lengua de Señas Mexicana (LSM) a partir del texto proporcionado.'),
            _bullet('Notificaciones',
                'Para enviar alertas relacionadas con el servicio.'),
            const SizedBox(height: 20),
            _heading('3. Almacenamiento y seguridad'),
            _body(
              'Los datos sensibles (credenciales de acceso y tokens) se almacenan '
              'localmente en el dispositivo con cifrado AES-256. El administrador '
              'puede eliminarlos de forma remota mediante una notificación FCM '
              'autorizada.\n\nNo compartimos tu información personal con terceros, '
              'anunciantes ni servicios de análisis externos.',
            ),
            const SizedBox(height: 20),
            _heading('4. Retención de datos'),
            _body(
              'Los datos de la cuenta se conservan mientras el usuario mantenga '
              'su cuenta activa. Puedes solicitar la eliminación de tu cuenta y '
              'datos asociados contactando al desarrollador.',
            ),
            const SizedBox(height: 20),
            _heading('5. Permisos del dispositivo'),
            _bullet('Internet',
                'Para comunicarse con el servidor de la API.'),
            _bullet('Ubicación',
                'Para funciones contextuales de la aplicación.'),
            _bullet('Notificaciones',
                'Para recibir alertas del servicio.'),
            const SizedBox(height: 20),
            _heading('6. Menores de edad'),
            _body(
              'VirtualSign LSM no está dirigida a menores de 13 años. No '
              'recopilamos intencionalmente información de menores de edad.',
            ),
            const SizedBox(height: 20),
            _heading('7. Cambios a esta política'),
            _body(
              'Podemos actualizar esta política en cualquier momento. '
              'Notificaremos los cambios significativos a través de la '
              'aplicación. El uso continuo implica la aceptación de la '
              'nueva política.',
            ),
            const SizedBox(height: 20),
            _heading('8. Contacto'),
            _body('Para cualquier pregunta sobre esta política, contáctanos en:'),
            const SizedBox(height: 6),
            Text(
              'virtualsignsupport@gmail.com',
              style: const TextStyle(
                color: Color(0xFF4F8EF7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Divider(color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 12),
            Text(
              '© 2026 KitsuneDev – VirtualSign LSM. Todos los derechos reservados.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4F8EF7),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _meta(String text) => Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            height: 1.7,
          ),
        ),
      );

  Widget _bullet(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF06D6A0),
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: desc,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
