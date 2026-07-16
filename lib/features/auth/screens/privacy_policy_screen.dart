import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.dark : AppGradients.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: context.textPrimary,
          title: Text(
            'Política de Privacidad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary, size: 18),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: context.dividerColor),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'VirtualSign LSM — Política de Privacidad'),
              _meta(context, 'Desarrollador: KitsuneDev'),
              _meta(context, 'Última actualización: 26 de junio de 2026'),
              const SizedBox(height: 16),
              _body(
                context,
                'Esta Política de Privacidad describe cómo VirtualSign LSM recopila, '
                'usa y protege la información de sus usuarios. Al utilizar la '
                'aplicación, aceptas los términos descritos en este documento.',
              ),
              const SizedBox(height: 24),

              _heading(context, '1. Información que recopilamos'),
              _bullet(context, 'Correo electrónico y contraseña',
                  'Necesarios para crear una cuenta e iniciar sesión.'),
              _bullet(context, 'Texto ingresado por el usuario',
                  'El texto que introduces para generar las señas en LSM. Se envía al servidor únicamente para procesar la solicitud y no se almacena de forma permanente.'),
              _bullet(context, 'Ubicación geográfica',
                  'Se solicita acceso a la ubicación del dispositivo para funciones contextuales. No se comparte con terceros.'),
              _bullet(context, 'Token de dispositivo (Firebase)',
                  'Se utiliza exclusivamente para el envío de notificaciones push.'),
              const SizedBox(height: 20),

              _heading(context, '2. Cómo usamos la información'),
              _bullet(context, 'Autenticación',
                  'Para autenticar al usuario mediante JWT (JSON Web Tokens).'),
              _bullet(context, 'Generación de señas',
                  'Para generar videos de Lengua de Señas Mexicana (LSM) a partir del texto proporcionado.'),
              _bullet(context, 'Notificaciones',
                  'Para enviar alertas relacionadas con el servicio.'),
              const SizedBox(height: 20),

              _heading(context, '3. Almacenamiento y seguridad'),
              _body(
                context,
                'Los datos sensibles (credenciales de acceso y tokens) se almacenan '
                'localmente en el dispositivo con cifrado AES-256. El administrador '
                'puede eliminarlos de forma remota mediante una notificación FCM '
                'autorizada.\n\nNo compartimos tu información personal con terceros, '
                'anunciantes ni servicios de análisis externos.',
              ),
              const SizedBox(height: 20),

              _heading(context, '4. Retención de datos'),
              _body(
                context,
                'Los datos de la cuenta se conservan mientras el usuario mantenga '
                'su cuenta activa. Puedes solicitar la eliminación de tu cuenta y '
                'datos asociados contactando al desarrollador.',
              ),
              const SizedBox(height: 20),

              _heading(context, '5. Permisos del dispositivo'),
              _bullet(context, 'Internet',
                  'Para comunicarse con el servidor de la API.'),
              _bullet(context, 'Ubicación',
                  'Para funciones contextuales de la aplicación.'),
              _bullet(context, 'Notificaciones',
                  'Para recibir alertas del servicio.'),
              const SizedBox(height: 20),

              _heading(context, '6. Menores de edad'),
              _body(
                context,
                'VirtualSign LSM no está dirigida a menores de 13 años. No '
                'recopilamos intencionalmente información de menores de edad.',
              ),
              const SizedBox(height: 20),

              _heading(context, '7. Cambios a esta política'),
              _body(
                context,
                'Podemos actualizar esta política en cualquier momento. '
                'Notificaremos los cambios significativos a través de la '
                'aplicación. El uso continuo implica la aceptación de la '
                'nueva política.',
              ),
              const SizedBox(height: 20),

              _heading(context, '8. Contacto'),
              _body(context,
                  'Para cualquier pregunta sobre esta política, contáctanos en:'),
              const SizedBox(height: 6),
              Text(
                'virtualsignsupport@gmail.com',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              Divider(color: context.dividerColor),
              const SizedBox(height: 12),
              Text(
                '© 2026 KitsuneDev – VirtualSign LSM. Todos los derechos reservados.',
                style: TextStyle(color: context.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _meta(BuildContext context, String text) => Text(
        text,
        style: TextStyle(color: context.textSecondary, fontSize: 12),
      );

  Widget _heading(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _body(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            height: 1.7,
          ),
        ),
      );

  Widget _bullet(BuildContext context, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: desc,
                      style: TextStyle(
                        color: context.textSecondary,
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
