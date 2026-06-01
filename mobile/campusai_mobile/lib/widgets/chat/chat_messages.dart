import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';
import '../../services/source_service.dart';
import '../typing_dots.dart';
import 'chat_bubble.dart';
import 'citation_chips.dart';
import 'empty_chat_state.dart';
import 'source_viewer_sheet.dart';

class ChatMessages extends StatefulWidget {
  final List<ChatMessageModel> messages;
  final bool isLoading;

  const ChatMessages({
    super.key,
    required this.messages,
    required this.isLoading,
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  Widget buildTypingIndicator() {
    if (!widget.isLoading) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TypingDots(),
            SizedBox(width: 14),
            Text(
              'StudyBook AI está pensando...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showCitationSource(String citation) async {
    debugPrint('Citation clicked: $citation');

    final match = RegExp(
      r'\[FUENTE document=([^\s\]]+) chunk=(\d+)\]',
    ).firstMatch(citation);

    if (match == null) return;

    final documentId = match.group(1) ?? '';

    final chunkIndex = int.tryParse(
          match.group(2) ?? '',
        ) ??
        0;

    if (documentId.isEmpty) return;

    debugPrint('Document ID: $documentId');
    debugPrint('Chunk Index: $chunkIndex');

    try {
      debugPrint('Calling source endpoint...');

      final source = await SourceService.getSourceChunk(
        documentId: documentId,
        chunkIndex: chunkIndex,
      );

      debugPrint('Source loaded successfully');
      
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          return FractionallySizedBox(
            heightFactor: 0.72,
            child: SourceViewerSheet(
              documentId: source['document_id'] ?? documentId,
              chunkIndex: source['chunk_index'] ?? chunkIndex,
              content: source['content'] ?? '',
              metadata: Map<String, dynamic>.from(
                source['metadata'] ?? {},
              ),
            ),
          );
        },
      );
    } catch (error) {
      debugPrint('Source loaded successfully');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cargar la fuente: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        120,
      ),
      children: [
        EmptyChatState(
          shouldShow: widget.messages.isEmpty && !widget.isLoading,
        ),
        ...widget.messages.map(
          (message) {
            return Column(
              crossAxisAlignment:
                  message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                ChatBubble(
                  text: message.text,
                  isUser: message.isUser,
                  createdAt: message.createdAt,
                ),
                if (!message.isUser &&
                    message.citations.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 14,
                        top: 4,
                        bottom: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CitationChips(
                        text: message.text,
                        citations: message.citations,
                        onCitationTap: showCitationSource,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        buildTypingIndicator(),
      ],
    );
  }
}
