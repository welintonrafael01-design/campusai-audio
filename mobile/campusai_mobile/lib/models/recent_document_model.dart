class RecentDocumentModel {
  final String documentId;
  final String fileName;
  final String summary;
  final String audioUrl;
  final DateTime lastOpenedAt;

  const RecentDocumentModel({
    required this.documentId,
    required this.fileName,
    required this.summary,
    required this.audioUrl,
    required this.lastOpenedAt,
  });

  RecentDocumentModel copyWith({
    String? documentId,
    String? fileName,
    String? summary,
    String? audioUrl,
    DateTime? lastOpenedAt,
  }) {
    return RecentDocumentModel(
      documentId: documentId ?? this.documentId,
      fileName: fileName ?? this.fileName,
      summary: summary ?? this.summary,
      audioUrl: audioUrl ?? this.audioUrl,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'fileName': fileName,
      'summary': summary,
      'audioUrl': audioUrl,
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
    };
  }

  factory RecentDocumentModel.fromJson(Map<String, dynamic> json) {
    return RecentDocumentModel(
      documentId: json['documentId'] ?? '',
      fileName: json['fileName'] ?? 'Documento',
      summary: json['summary'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] ?? '') ??
          DateTime.now(),
    );
  }
}
