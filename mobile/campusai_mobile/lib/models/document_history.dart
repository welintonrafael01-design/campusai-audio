class DocumentHistory {
  final String documentId;
  final String fileName;
  final String summary;
  final String audioUrl;
  final String createdAt;

  const DocumentHistory({
    required this.documentId,
    required this.fileName,
    required this.summary,
    required this.audioUrl,
    required this.createdAt,
  });

  factory DocumentHistory.empty() {
    return const DocumentHistory(
      documentId: '',
      fileName: '',
      summary: '',
      audioUrl: '',
      createdAt: '',
    );
  }

  bool get hasAudio => audioUrl.trim().isNotEmpty;

  bool get hasSummary => summary.trim().isNotEmpty;

  bool get isValid =>
      documentId.trim().isNotEmpty && fileName.trim().isNotEmpty;

  String get cleanSummary {
    return summary
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('*', '')
        .trim();
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'fileName': fileName,
      'summary': summary,
      'audioUrl': audioUrl,
      'createdAt': createdAt,
    };
  }

  factory DocumentHistory.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DocumentHistory.empty();
    }

    return DocumentHistory(
      documentId: _safeString(json['documentId']),
      fileName: _safeString(json['fileName']),
      summary: _safeString(json['summary']),
      audioUrl: _safeString(json['audioUrl']),
      createdAt: _safeString(json['createdAt']),
    );
  }

  DocumentHistory copyWith({
    String? documentId,
    String? fileName,
    String? summary,
    String? audioUrl,
    String? createdAt,
  }) {
    return DocumentHistory(
      documentId: documentId ?? this.documentId,
      fileName: fileName ?? this.fileName,
      summary: summary ?? this.summary,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _safeString(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }

  @override
  String toString() {
    return 'DocumentHistory(documentId: $documentId, fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DocumentHistory &&
        documentId.isNotEmpty &&
        other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.isEmpty ? super.hashCode : documentId.hashCode;
}