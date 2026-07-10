import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
            'Términos y Condiciones',
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
              _sectionTitle(context, 'VirtualSign LSM — Términos y Condiciones de Uso'),
              _meta(context, 'Desarrollador: KitsuneDev'),
              _meta(context, 'Última actualización: 26 de junio de 2026'),
              const SizedBox(height: 16),
              _body(
                context,
                'Al registrarte y usar VirtualSign LSM, aceptas quedar vinculado '
                'por estos Términos y Condiciones. Si no estás de acuerdo con '
                'alguno de ellos, no debes utilizar la aplicación.',
              ),
              const SizedBox(height: 24),

              _heading(context, '1. Descripción del servicio'),
              _body(
                context,
                'VirtualSign LSM es una aplicación móvil que convierte texto en '
                'animaciones de Lengua de Señas Mexicana (LSM) mediante avatares '
                'digitales. El servicio incluye un generador de señas por texto, '
                'un diccionario de vocabulario LSM y un historial de generaciones.',
              ),
              const SizedBox(height: 20),

              _heading(context, '2. Cuenta de usuario'),
              _bullet(context, 'Registro',
                  'Para usar la aplicación debes crear una cuenta con un correo electrónico válido y una contraseña segura.'),
              _bullet(context, 'Responsabilidad',
                  'Eres responsable de mantener la confidencialidad de tu contraseña y de todas las actividades realizadas desde tu cuenta.'),
              _bullet(context, 'Veracidad',
                  'Debes proporcionar información veraz y actualizada durante el registro.'),
              const SizedBox(height: 20),

              _heading(context, '3. Uso aceptable'),
              _body(context, 'Al utilizar VirtualSign LSM te comprometes a:'),
              _bullet(context, 'Uso personal',
                  'Usar la aplicación únicamente para fines educativos y de comunicación.'),
              _bullet(context, 'Prohibiciones',
                  'No reproducir, distribuir ni explotar comercialmente los videos generados sin autorización expresa de KitsuneDev.'),
              _bullet(context, 'Contenido',
                  'No introducir texto que contenga lenguaje ofensivo, amenazas o contenido ilegal para generar señas.'),
              _bullet(context, 'Ingeniería inversa',
                  'No intentar descompilar, modificar ni realizar ingeniería inversa del servicio o sus componentes.'),
              const SizedBox(height: 20),

              _heading(context, '4. Propiedad intelectual'),
              _body(
                context,
                'Los avatares, animaciones, algoritmos de generación de señas y '
                'el contenido del diccionario son propiedad de KitsuneDev o de '
                'sus respectivos titulares de derechos. El uso de la aplicación '
                'no te otorga ningún derecho de propiedad sobre dichos elementos.',
              ),
              const SizedBox(height: 20),

              _heading(context, '5. Limitación de responsabilidad'),
              _body(
                context,
                'VirtualSign LSM se ofrece "tal cual" sin garantías de ningún '
                'tipo. KitsuneDev no será responsable de daños directos, '
                'indirectos o incidentales que puedan derivarse del uso o '
                'la imposibilidad de uso de la aplicación.',
              ),
              _body(
                context,
                'Las traducciones a LSM generadas por la aplicación son de '
                'carácter orientativo y no sustituyen la interpretación de un '
                'intérprete certificado.',
              ),
              const SizedBox(height: 20),

              _heading(context, '6. Cancelación de cuenta'),
              _body(
                context,
                'Puedes eliminar tu cuenta en cualquier momento desde la sección '
                'de perfil de la aplicación. Esto eliminará permanentemente tus '
                'datos y el historial de generaciones almacenado en el servidor.',
              ),
              const SizedBox(height: 20),

              _heading(context, '7. Modificaciones del servicio'),
              _body(
                context,
                'KitsuneDev se reserva el derecho de modificar, suspender o '
                'discontinuar el servicio en cualquier momento. En caso de '
                'cambios significativos, se notificará a través de la aplicación.',
              ),
              const SizedBox(height: 20),

              _heading(context, '8. Ley aplicable'),
              _body(
                context,
                'Estos términos se rigen por las leyes de los Estados Unidos '
                'Mexicanos. Cualquier disputa será sometida a la jurisdicción '
                'de los tribunales competentes de México.',
              ),
              const SizedBox(height: 20),

              _heading(context, '9. Contacto'),
              _body(context,
                  'Para consultas sobre estos términos, contáctanos en:'),
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
