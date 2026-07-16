import '../../../../core/network/api_client.dart';
import '../models/merged_video_model.dart';

/// Fuente de datos remota del generador de señas.
///
/// Responsabilidad única: ejecutar la llamada HTTP a
/// POST /signs/generate/merged y deserializar la respuesta.
class GeneratorRemoteDataSource {
  const GeneratorRemoteDataSource();

  /// Genera el video fusionado LSM para [text] con el avatar [avatarCode].
  /// Lanza [ApiException] si el servidor devuelve error.
  Future<MergedVideoModel> generateMerged({
    required String text,
    required String avatarCode,
    required String token,
  }) async {
    final data = await ApiClient.post(
      '/signs/generate/merged',
      {'text': text, 'avatarCode': avatarCode},
      token: token,
    );
    return MergedVideoModel.fromJson(data);
  }
}
