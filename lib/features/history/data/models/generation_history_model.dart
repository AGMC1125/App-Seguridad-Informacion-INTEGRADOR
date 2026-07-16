import '../../domain/entities/generation_history.dart';

/// DTO que mapea el JSON de la API al dominio.
///
/// Responsabilidad única: deserializar el JSON y convertirlo
/// a la entidad de dominio [GenerationHistory] mediante [toEntity()].
class GenerationHistoryModel {
  final int id;
  final String originalText;
  final String avatarCode;
  final String? generatedFilename;
  final String? mergedVideoUrl;
  final DateTime createdAt;

  const GenerationHistoryModel({
    required this.id,
    required this.originalText,
    required this.avatarCode,
    this.generatedFilename,
    this.mergedVideoUrl,
    required this.createdAt,
  });

  factory GenerationHistoryModel.fromJson(Map<String, dynamic> json) {
    return GenerationHistoryModel(
      id: json['id'] as int,
      originalText: json['originalText'] as String,
      avatarCode: json['avatarCode'] as String,
      generatedFilename: json['generatedFilename'] as String?,
      mergedVideoUrl: json['mergedVideoUrl'] as String?,
      // toLocal() convierte el timestamp UTC de la API a la zona horaria del dispositivo
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  GenerationHistory toEntity() {
    return GenerationHistory(
      id: id,
      originalText: originalText,
      avatarCode: avatarCode,
      generatedFilename: generatedFilename,
      mergedVideoUrl: mergedVideoUrl,
      createdAt: createdAt,
    );
  }
}
