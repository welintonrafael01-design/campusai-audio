class AudiobookHistory {
  final String documentId;
  final String fileName;
  final List<Map<String, dynamic>> chapters;
  final String createdAt;

  const AudiobookHistory({
    required this.documentId,
    required this.fileName,
    required this.chapters,
    required this.createdAt,
  });

  int get chapterCount => chapters.length;

  bool get isValid =>
      documentId.trim().isNotEmpty &&
      fileName.trim().isNotEmpty &&
      chapters.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'fileName': fileName,
      'chapters': chapters,
      'createdAt': createdAt,
    };
  }

  factory AudiobookHistory.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AudiobookHistory(
        documentId: '',
        fileName: '',
        chapters: [],
        createdAt: '',
      );
    }

    final rawChapters = json['chapters'];
    final chapters = rawChapters is List
        ? rawChapters
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    return AudiobookHistory(
      documentId: json['documentId']?.toString().trim() ?? '',
      fileName: json['fileName']?.toString().trim() ?? '',
      chapters: chapters,
      createdAt: json['createdAt']?.toString().trim() ?? '',
    );
  }
}
