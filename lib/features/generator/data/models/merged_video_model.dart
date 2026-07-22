import '../../domain/entities/merged_video_result.dart';
import '../../domain/entities/sign_interpretation.dart';

/// Modelo de datos: deserializa la respuesta JSON de POST /signs/generate/merged.
class MergedVideoModel {
  final String avatarCode;
  final String originalText;
  final String mergedVideoUrl;
  final String generatedFilename;
  final List<String> unsupportedCharacters;
  final List<SignInterpretation> interpretations;

  const MergedVideoModel({
    required this.avatarCode,
    required this.originalText,
    required this.mergedVideoUrl,
    required this.generatedFilename,
    required this.unsupportedCharacters,
    required this.interpretations,
  });

  factory MergedVideoModel.fromJson(Map<String, dynamic> json) {
    return MergedVideoModel(
      avatarCode: json['avatarCode'] as String,
      originalText: json['originalText'] as String,
      mergedVideoUrl: json['mergedVideoUrl'] as String,
      generatedFilename: json['generatedFilename'] as String,
      unsupportedCharacters:
          List<String>.from(json['unsupportedCharacters'] as List),
      // El backend puede omitir el campo en versiones previas: se trata como
      // lista vacía para no romper la compatibilidad.
      interpretations: ((json['interpretations'] as List?) ?? [])
          .map((e) => SignInterpretation(
                original: (e as Map<String, dynamic>)['original'] as String,
                interpreted: e['interpreted'] as String,
              ))
          .toList(),
    );
  }

  MergedVideoResult toEntity() => MergedVideoResult(
        avatarCode: avatarCode,
        originalText: originalText,
        mergedVideoUrl: mergedVideoUrl,
        generatedFilename: generatedFilename,
        unsupportedCharacters: unsupportedCharacters,
        interpretations: interpretations,
      );
}
