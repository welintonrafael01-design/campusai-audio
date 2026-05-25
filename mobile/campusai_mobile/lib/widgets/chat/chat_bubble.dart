import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../layout/responsive_layout.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  void copyMessage(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Respuesta copiada al portapapeles.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isDesktop(context) ? 620 : 340,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser ? AppTheme.mainGradient : null,
          color: isUser ? null : AppTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 8),
            bottomRight: Radius.circular(isUser ? 8 : 24),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
  data: text,
  selectable: true,
  styleSheet: MarkdownStyleSheet(
    p: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 15.5,
      height: 1.6,
    ),

    h1: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w900,
    ),

    h2: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),

    h3: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    ),

    strong: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),

    listBullet: const TextStyle(
      color: AppTheme.accent,
      fontWeight: FontWeight.bold,
    ),

    code: TextStyle(
      color: AppTheme.accent,
      backgroundColor:
          Colors.black.withValues(alpha: 0.22),
      fontSize: 14,
    ),

    blockquote: const TextStyle(
      color: AppTheme.textSecondary,
      fontStyle: FontStyle.italic,
    ),
  ),
),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatTime(createdAt),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => copyMessage(context),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}