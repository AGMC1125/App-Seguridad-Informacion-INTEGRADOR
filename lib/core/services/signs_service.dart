import '../constants/app_constants.dart';
import 'api_client.dart';
import 'auth_service.dart';
import '../../features/home/models/sign_result.dart';
import '../../features/home/models/merged_video_result.dart';

/// Servicio para generar señas LSM a partir de texto.
class SignsService {
  SignsService._();

  /// Genera la lista de videos LSM por letra (flujo original).
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

  /// Genera un único video fusionado con todas las señas del texto.
  /// El servidor usa FFmpeg para concatenar los clips — puede tardar varios segundos.
  static Future<MergedVideoResult> generateMerged({
    required String text,
    required String avatarCode,
  }) async {
    final token = await AuthService.getToken();
    final data = await ApiClient.post(
      '/signs/generate/merged',
      {'text': text, 'avatarCode': avatarCode},
      token: token,
    );
    return MergedVideoResult.fromJson(data);
  }

  /// Construye la URL absoluta de un path relativo devuelto por la API.
  static String buildVideoUrl(String relativePath) {
    return '${AppConstants.apiBaseUrl}$relativePath';
  }
}
