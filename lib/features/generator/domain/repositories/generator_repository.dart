import '../entities/merged_video_result.dart';

/// Contrato de dominio para el generador de señas LSM.
abstract class GeneratorRepository {
  /// Genera un video fusionado para el [text] dado con el [avatarCode] indicado.
  Future<MergedVideoResult> generateMerged({
    required String text,
    required String avatarCode,
    required String token,
  });
}
