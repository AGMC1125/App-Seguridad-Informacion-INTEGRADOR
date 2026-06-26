import '../constants/app_constants.dart';
import 'api_client.dart';
import 'auth_service.dart';
import '../../features/home/models/sign_result.dart';

/// Servicio para generar señas LSM a partir de texto.
///
/// Llama a POST /signs/generate en la API Spring Boot.
/// Requiere JWT activo — se obtiene automáticamente del almacén.
class SignsService {
  SignsService._();

  /// Genera la lista de videos LSM para [text] usando el [avatarCode] dado.
  ///
  /// [avatarCode] debe ser uno de: nino, nina, hombre_adulto, mujer_adulta
  ///
  /// Retorna un [SignResult] con las URLs de video y los caracteres no soportados.
  /// Lanza [ApiException] si la API responde con error.
  static Future<SignResult> generate({
    required String text,
    required String avatarCode,
  }) async {
    final token = await AuthService.getToken();

    final data = await ApiClient.post(
      '/signs/generate',
      {'text': text, 'avatarCode': avatarCode},
      token: token,
    );

    return SignResult.fromJson(data);
  }

  /// Construye la URL completa de un video relativo devuelto por la API.
  ///
  /// Ej: "/signs/hombre_adulto/H.mp4" → "http://10.60.2.227:8080/signs/hombre_adulto/H.mp4"
  static String buildVideoUrl(String relativePath) {
    return '${AppConstants.apiBaseUrl}$relativePath';
  }
}
