import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/responsive_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';
import '../../services/plan_guard_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/upgrade_dialog.dart';

class ChatBubble extends ConsumerStatefulWidget {
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  @override
  ConsumerState<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<ChatBubble> {
  bool isGeneratingAudio = false;

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String cleanVisibleText() {
    return widget.text
        .replaceAll(
          RegExp(r'\[FUENTE document=[^\s\]]+ chunk=\d+\]'),
          '',
        )
        .replaceAll(
          RegExp(r'\[FUENTE chunk=\d+\]'),
          '',
        )
        .replaceAll(
          RegExp(r'Fuentes utilizadas\s*\n\s*[-•]?\s*', caseSensitive: false),
          'Fuentes utilizadas',
        )
        .trim();
  }

  void copyMessage(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: widget.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).answerCopied),
      ),
    );
  }

  Future<void> listenAnswer(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleanText = cleanVisibleText();
    final audioTitle = l10n.voiceAnswerAudioTitle;
    final loadingMessage = l10n.generatingAnswerAudio;
    final errorMessage = l10n.answerAudioError;

    if (!const PlanGuardService().canUseVoiceOnboarding) {
      showUpgradeRequired(
        context,
        featureName: l10n.listenAnswer,
      );
      return;
    }

    if (cleanText.trim().isEmpty || isGeneratingAudio) return;

    setState(() {
      isGeneratingAudio = true;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(loadingMessage),
      ),
    );

    try {
      final data = await ApiService.generateAudioFromText(
        text: cleanText,
      );

      final audioUrl = data['audio_url']?.toString() ?? '';

      if (audioUrl.trim().isEmpty) {
        throw Exception('Audio URL empty');
      }

      final fullAudioUrl = ApiService.buildAudioUrl(audioUrl);

      await ref.read(audioProvider.notifier).play(
            audioUrl: fullAudioUrl,
            title: audioTitle,
          );
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingAudio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.isUser;
    final canUseVoiceAudio = const PlanGuardService().canUseVoiceOnboarding;

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
              data: cleanVisibleText(),
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
                  backgroundColor: Colors.black.withValues(alpha: 0.22),
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
                  formatTime(widget.createdAt),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 12),
                  Tooltip(
                    message: AppLocalizations.of(context).answerCopied,
                    child: GestureDetector(
                      onTap: () => copyMessage(context),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: AppLocalizations.of(context).listenAnswer,
                    child: GestureDetector(
                      onTap: () => listenAnswer(context),
                      child: isGeneratingAudio
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  size: 18,
                                  color: canUseVoiceAudio
                                      ? AppTheme.accent
                                      : AppTheme.textMuted,
                                ),
                                if (!canUseVoiceAudio)
                                  Positioned(
                                    right: -7,
                                    bottom: -5,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white,
                                        size: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
