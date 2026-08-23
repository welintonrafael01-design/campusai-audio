import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';
import '../../services/source_service.dart';
import '../typing_dots.dart';
import 'chat_bubble.dart';
import 'empty_chat_state.dart';
import 'source_references_section.dart';
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
    final l10n = AppLocalizations.of(context);
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TypingDots(),
            const SizedBox(width: 14),
            Text(
              l10n.aiThinking,
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

  Future<void> showCitationSource(ChatCitationModel citation) async {
    final documentId = citation.documentId;
    final chunkIndex = citation.chunkIndex;

    if (documentId.isEmpty) return;

    try {
      final source = await SourceService.getSourceChunk(
        documentId: documentId,
        chunkIndex: chunkIndex,
      );

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
              content: source['content'] ?? '',
              metadata: Map<String, dynamic>.from(
                source['metadata'] ?? {},
              ),
            ),
          );
        },
      );
    } catch (error) {
      debugPrint('No se pudo abrir la fuente citada: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sourceLoadError),
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
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ChatBubble(
                  text: message.text,
                  isUser: message.isUser,
                  createdAt: message.createdAt,
                ),
                if (!message.isUser && message.citations.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 14,
                        top: 4,
                        bottom: 18,
                      ),
                      child: SourceReferencesSection(
                        sources: message.citations,
                        onSourceTap: showCitationSource,
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
