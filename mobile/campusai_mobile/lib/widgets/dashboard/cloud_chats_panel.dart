import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
  State<CloudChatsPanel> createState() => _CloudChatsPanelState();
}

class _CloudChatsPanelState extends State<CloudChatsPanel> {
  bool isLoading = true;
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> renameChat(
    String chatId,
    String currentTitle,
  ) async {
    final controller = TextEditingController(
      text: currentTitle,
    );

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            AppLocalizations.of(context).renameConversation,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).newName,
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                controller.text.trim(),
              ),
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newTitle == null || newTitle.isEmpty) return;

    try {
      await CloudApiService.updateChatTitle(
        chatId: chatId,
        title: newTitle,
      );

      await loadChats();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).renameConversationError),
        ),
      );
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await CloudApiService.deleteChat(chatId: chatId);
      await loadChats();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).deleteConversationError),
        ),
      );
    }
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
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentConversations,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Text(
              l10n.loadingConversations,
              style: TextStyle(
                color: AppTheme.textMuted,
              ),
            )
          else if (chats.isEmpty)
            Text(
              l10n.noSavedConversations,
              style: TextStyle(
                color: AppTheme.textMuted,
              ),
            )
          else
            ...chats.take(5).map((chat) {
              final chatMap = Map<String, dynamic>.from(chat as Map);

              final title = chatMap['title'] ?? l10n.untitledConversation;

              final createdAt = chatMap['created_at'] ?? '';

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
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: l10n.renameConversation,
                        onPressed: () {
                          renameChat(
                            chatMap['id'].toString(),
                            title.toString(),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.deleteConversation,
                        onPressed: () {
                          deleteChat(
                            chatMap['id'].toString(),
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.textMuted,
                          size: 18,
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
