/// Respuesta de la API Spring Boot para POST /signs/generate.
class SignResult {
  /// Código del avatar utilizado (ej. "hombre_adulto").
  final String avatarCode;

  /// Texto original enviado por el usuario.
  final String originalText;

  /// URLs relativas de los videos por cada letra/token.
  /// Ej: ["/signs/hombre_adulto/H.mp4", "/signs/hombre_adulto/O.mp4"]
  final List<String> videoUrls;

  /// Letras/tokens sin video disponible en el diccionario.
  final List<String> unsupportedCharacters;

  const SignResult({
    required this.avatarCode,
    required this.originalText,
    required this.videoUrls,
    required this.unsupportedCharacters,
  });

  factory SignResult.fromJson(Map<String, dynamic> json) => SignResult(
        avatarCode: json['avatarCode'] as String,
        originalText: json['originalText'] as String,
        videoUrls: List<String>.from(json['videoUrls'] as List),
        unsupportedCharacters:
            List<String>.from(json['unsupportedCharacters'] as List),
      );
}
