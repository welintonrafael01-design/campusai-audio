class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isStreaming;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.isStreaming = false,
  });

  ChatMessageModel copyWith({
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isStreaming,
  }) {
    return ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt,
      'isStreaming': isStreaming,
    };
  }
}
