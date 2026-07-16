import '../entities/merged_video_result.dart';
import '../repositories/generator_repository.dart';

/// Caso de uso: generar video LSM fusionado a partir de texto.
class GenerateMergedVideoUseCase {
  final GeneratorRepository _repository;
  const GenerateMergedVideoUseCase(this._repository);

  Future<MergedVideoResult> call({
    required String text,
    required String avatarCode,
    required String token,
  }) {
    return _repository.generateMerged(
      text: text,
      avatarCode: avatarCode,
      token: token,
    );
  }
}
