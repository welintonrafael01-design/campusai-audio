import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
            '${AppLocalizations.of(context).sourceLoadError}: $error',
          ),
        ),
      );
    }
  }

  Widget buildConfidenceBanner(ChatMessageModel message) {
    if (message.isUser) return const SizedBox.shrink();

    final confidence = message.confidence;
    final confidenceMessage = message.confidenceMessage;

    if (confidence == null || confidence.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    IconData icon = Icons.help_outline_rounded;
    String label = AppLocalizations.of(context).unknownConfidence;
    Color color = AppTheme.textMuted;

    if (confidence == 'high') {
      icon = Icons.verified_rounded;
      label = AppLocalizations.of(context).highConfidence;
      color = Colors.greenAccent;
    } else if (confidence == 'medium') {
      icon = Icons.info_rounded;
      label = AppLocalizations.of(context).mediumConfidence;
      color = Colors.amberAccent;
    } else if (confidence == 'low') {
      icon = Icons.warning_rounded;
      label = AppLocalizations.of(context).lowConfidence;
      color = Colors.redAccent;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          left: 14,
          top: 8,
          bottom: 6,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                confidenceMessage == null || confidenceMessage.trim().isEmpty
                    ? label
                    : '$label · $confidenceMessage',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                if (!message.isUser) buildConfidenceBanner(message),
                ChatBubble(
                  text: message.text,
                  isUser: message.isUser,
                  createdAt: message.createdAt,
                ),
                if (!message.isUser && message.citations.isNotEmpty)
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
