/// Entidad de dominio que representa un registro del historial de generaciones.
///
/// Pertenece exclusivamente a la capa de dominio: no depende de Flutter,
/// ni de HTTP, ni de ningún paquete externo. El parseo JSON vive en el modelo
/// de la capa de datos.
class GenerationHistory {
  final int id;
  final String originalText;
  final String avatarCode;
  final String? generatedFilename;
  final String? mergedVideoUrl;
  final DateTime createdAt;

  const GenerationHistory({
    required this.id,
    required this.originalText,
    required this.avatarCode,
    this.generatedFilename,
    this.mergedVideoUrl,
    required this.createdAt,
  });
}
