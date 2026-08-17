class ChatCitationModel {
  final String documentId;
  final int chunkIndex;
  final String? preview;
  final String? highlight;
  final double? distance;

  const ChatCitationModel({
    required this.documentId,
    required this.chunkIndex,
    this.preview,
    this.highlight,
    this.distance,
  });

  factory ChatCitationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ChatCitationModel(
      documentId: map['document_id'] ?? '',
      chunkIndex: map['chunk_index'] ?? 0,
      preview: map['preview'],
      highlight: map['highlight'],
      distance:
          map['distance'] is num ? (map['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'chunk_index': chunkIndex,
      'preview': preview,
      'highlight': highlight,
      'distance': distance,
    };
  }
}

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isStreaming;

  final String? confidence;
  final double? averageDistance;
  final String? confidenceMessage;

  final List<ChatCitationModel> citations;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isStreaming = false,
    this.confidence,
    this.averageDistance,
    this.confidenceMessage,
    this.citations = const [],
  });

  ChatMessageModel copyWith({
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isStreaming,
    String? confidence,
    double? averageDistance,
    String? confidenceMessage,
    List<ChatCitationModel>? citations,
  }) {
    return ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
      confidence: confidence ?? this.confidence,
      averageDistance: averageDistance ?? this.averageDistance,
      confidenceMessage: confidenceMessage ?? this.confidenceMessage,
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
