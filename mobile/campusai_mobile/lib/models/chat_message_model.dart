class ChatCitationModel {
  final String documentId;
  final int chunkIndex;
  final String? documentTitle;
  final String? preview;
  final String? highlight;
  final double? distance;
  final int? pageNumber;

  const ChatCitationModel({
    required this.documentId,
    required this.chunkIndex,
    this.documentTitle,
    this.preview,
    this.highlight,
    this.distance,
    this.pageNumber,
  });

  factory ChatCitationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ChatCitationModel(
      documentId: map['document_id'] ?? '',
      chunkIndex: map['chunk_index'] ?? 0,
      documentTitle: map['document_title']?.toString(),
      preview: map['preview'],
      highlight: map['highlight'],
      distance:
          map['distance'] is num ? (map['distance'] as num).toDouble() : null,
      pageNumber: map['page_number'] is num
          ? (map['page_number'] as num).toInt()
          : int.tryParse(map['page_number']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'chunk_index': chunkIndex,
      'document_title': documentTitle,
      'preview': preview,
      'highlight': highlight,
      'distance': distance,
      'page_number': pageNumber,
    };
  }
}

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isStreaming;

  final List<ChatCitationModel> citations;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isStreaming = false,
    this.citations = const [],
  });

  ChatMessageModel copyWith({
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isStreaming,
    List<ChatCitationModel>? citations,
  }) {
    return ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
      citations: citations ?? this.citations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
      'isStreaming': isStreaming,
      'citations': citations.map((item) => item.toMap()).toList(),
    };
  }
}
