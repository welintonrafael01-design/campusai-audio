import 'package:flutter/material.dart';

import '../../services/cloud_api_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class CloudChatsPanel extends StatefulWidget {
  final void Function(Map<String, dynamic> chat) onOpenChat;

  const CloudChatsPanel({
    super.key,
    required this.onOpenChat,
  });

  @override
  State<CloudChatsPanel> createState() =>
      _CloudChatsPanelState();
}

class _CloudChatsPanelState extends State<CloudChatsPanel> {
  bool isLoading = true;
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      final data = await CloudApiService.getChats();

      if (!mounted) return;

      setState(() {
        chats = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        chats = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversaciones recientes',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Text(
              'Cargando conversaciones...',
              style: TextStyle(
                color: AppTheme.textMuted,
              ),
            )
          else if (chats.isEmpty)
            const Text(
              'Aún no tienes conversaciones guardadas.',
              style: TextStyle(
                color: AppTheme.textMuted,
              ),
            )
          else
            ...chats.take(5).map((chat) {
              final chatMap =
                  Map<String, dynamic>.from(chat as Map);

              final title =
                  chatMap['title'] ?? 'Conversación sin título';

              final createdAt =
                  chatMap['created_at'] ?? '';

              return InkWell(
                onTap: () => widget.onOpenChat(chatMap),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        createdAt.toString().split('T').first,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
