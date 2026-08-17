class StudyResult {
  final String documentId;
  final String type;
  final String content;
  final String createdAt;

  const StudyResult({
    required this.documentId,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  bool get isValid {
    return documentId.trim().isNotEmpty &&
        type.trim().isNotEmpty &&
        content.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'type': type,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory StudyResult.fromJson(Map<String, dynamic> json) {
    return StudyResult(
      documentId: json['documentId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
