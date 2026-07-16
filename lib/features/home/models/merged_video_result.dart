/// Respuesta de POST /signs/generate/merged
class MergedVideoResult {
  /// Código del avatar usado.
  final String avatarCode;

  /// Texto original enviado.
  final String originalText;

  /// URL relativa del video fusionado: "/signs/generated/{uuid}.mp4"
  final String mergedVideoUrl;

  /// Nombre del archivo en el servidor (uuid.mp4).
  final String generatedFilename;

  /// Caracteres sin seña disponible que fueron omitidos.
  final List<String> unsupportedCharacters;

  const MergedVideoResult({
    required this.avatarCode,
    required this.originalText,
    required this.mergedVideoUrl,
    required this.generatedFilename,
    required this.unsupportedCharacters,
  });

  factory MergedVideoResult.fromJson(Map<String, dynamic> json) {
    return MergedVideoResult(
      avatarCode: json['avatarCode'] as String,
      originalText: json['originalText'] as String,
      mergedVideoUrl: json['mergedVideoUrl'] as String,
      generatedFilename: json['generatedFilename'] as String,
      unsupportedCharacters:
          List<String>.from(json['unsupportedCharacters'] as List),
    );
  }
}
