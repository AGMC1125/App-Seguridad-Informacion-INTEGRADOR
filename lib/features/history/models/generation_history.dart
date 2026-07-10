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

  factory GenerationHistory.fromJson(Map<String, dynamic> json) {
    return GenerationHistory(
      id: json['id'] as int,
      originalText: json['originalText'] as String,
      avatarCode: json['avatarCode'] as String,
      generatedFilename: json['generatedFilename'] as String?,
      mergedVideoUrl: json['mergedVideoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
