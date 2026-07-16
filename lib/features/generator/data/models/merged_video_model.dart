import '../../domain/entities/merged_video_result.dart';

/// Modelo de datos: deserializa la respuesta JSON de POST /signs/generate/merged.
class MergedVideoModel {
  final String avatarCode;
  final String originalText;
  final String mergedVideoUrl;
  final String generatedFilename;
  final List<String> unsupportedCharacters;

  const MergedVideoModel({
    required this.avatarCode,
    required this.originalText,
    required this.mergedVideoUrl,
    required this.generatedFilename,
    required this.unsupportedCharacters,
  });

  factory MergedVideoModel.fromJson(Map<String, dynamic> json) {
    return MergedVideoModel(
      avatarCode: json['avatarCode'] as String,
      originalText: json['originalText'] as String,
      mergedVideoUrl: json['mergedVideoUrl'] as String,
      generatedFilename: json['generatedFilename'] as String,
      unsupportedCharacters:
          List<String>.from(json['unsupportedCharacters'] as List),
    );
  }

  MergedVideoResult toEntity() => MergedVideoResult(
        avatarCode: avatarCode,
        originalText: originalText,
        mergedVideoUrl: mergedVideoUrl,
        generatedFilename: generatedFilename,
        unsupportedCharacters: unsupportedCharacters,
      );
}
