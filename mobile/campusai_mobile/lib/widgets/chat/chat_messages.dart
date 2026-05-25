import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';
import '../typing_dots.dart';
import 'chat_bubble.dart';
import 'empty_chat_state.dart';

class ChatMessages extends StatelessWidget {
  final List<ChatMessageModel> messages;
  final bool isLoading;

  const ChatMessages({
    super.key,
    required this.messages,
    required this.isLoading,
  });

  Widget buildTypingIndicator() {
    if (!isLoading) {
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
          shouldShow: messages.isEmpty && !isLoading,
        ),
        ...messages.map(
          (message) {
            return ChatBubble(
              text: message.text,
              isUser: message.isUser,
              createdAt: message.createdAt,
            );
          },
        ),
        buildTypingIndicator(),
      ],
    );
  }
}
