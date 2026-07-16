/// Entidad de dominio: resultado de generar un video fusionado LSM.
/// Sin dependencias de JSON — pura lógica de negocio.
class MergedVideoResult {
  final String avatarCode;
  final String originalText;

  /// Ruta relativa del video: "/signs/generated/{uuid}.mp4"
  final String mergedVideoUrl;

  /// Nombre del archivo en el servidor.
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
}
