import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/responsive_layout.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message_model.dart';
import '../providers/document_provider.dart';
import '../services/api_service.dart';
import '../services/chat_history_service.dart';
import '../services/cloud_api_service.dart';
import '../services/export_service.dart';
import '../services/plan_guard_service.dart';
import '../utils/upgrade_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/chat_messages.dart';
import '../widgets/sidebar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String documentId;
  final String fileName;
  final String cloudChatId;
  final List<String> workspaceDocumentIds;

  const ChatScreen({
    super.key,
    required this.documentId,
    required this.fileName,
    this.cloudChatId = '',
    this.workspaceDocumentIds = const [],
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController questionController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  String cloudChatId = '';
  Timer? fakeStreamTimer;

  List<ChatMessageModel> messages = [];

  List<String> get activeWorkspaceIds {
    final providerIds = ref.read(activeWorkspaceProvider);

    if (providerIds.isNotEmpty) {
      return providerIds;
    }

    if (widget.workspaceDocumentIds.isNotEmpty) {
      return widget.workspaceDocumentIds;
    }

    return [widget.documentId];
  }

  bool get isWorkspaceChat => activeWorkspaceIds.length > 1;

  List<String> get effectiveDocumentIds => activeWorkspaceIds;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    loadChatHistory();
  }

  @override
  void dispose() {
    fakeStreamTimer?.cancel();
    questionController.dispose();
    super.dispose();
  }

  Future<void> loadChatHistory() async {
    List<ChatMessageModel> savedMessages = [];

    if (widget.cloudChatId.trim().isNotEmpty) {
      try {
        final cloudMessages = await CloudApiService.getChatMessages(
          chatId: widget.cloudChatId,
        );

        savedMessages = cloudMessages.map((item) {
          final map = Map<String, dynamic>.from(item as Map);

          return ChatMessageModel(
            text: map['content'] ?? '',
            isUser: map['role'] == 'user',
            createdAt: DateTime.tryParse(
                  map['created_at'] ?? '',
                ) ??
                DateTime.now(),
          );
        }).toList();

        cloudChatId = widget.cloudChatId;
      } catch (error) {
        debugPrint(
          'No se pudo cargar historial cloud: $error',
        );
      }
    }

    if (savedMessages.isEmpty) {
      savedMessages = await ChatHistoryService.loadMessages(
        documentId: widget.documentId,
      );
    }

    if (!mounted) return;

    setState(() {
      messages.clear();

      if (savedMessages.isEmpty) {
        messages.add(
          ChatMessageModel(
            text: isWorkspaceChat
                ? l10n.workspaceChatWelcome(effectiveDocumentIds.length)
                : l10n.documentChatWelcome(widget.fileName),
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        messages.addAll(savedMessages);
      }
    });
  }

  Future<void> persistChat() async {
    await ChatHistoryService.saveMessages(
      documentId: widget.documentId,
      messages: messages,
    );
  }

  List<Map<String, String>> buildConversationHistory() {
    return messages
        .take(
          messages.length > 8 ? 8 : messages.length,
        )
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();
  }

  Future<void> ensureCloudChat() async {
    if (cloudChatId.isNotEmpty) return;

    debugPrint('STEP 1: Entrando a askQuestion');
    try {
      final cloudChat = await CloudApiService.createChat(
        documentId: widget.documentId,
        title: widget.fileName,
      );

      cloudChatId = cloudChat['id'] ?? '';
    } catch (error) {
      debugPrint('No se pudo crear chat cloud: $error');
    }
  }

  Future<void> saveCloudMessage({
    required String role,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    await ensureCloudChat();

    if (cloudChatId.isEmpty) return;

    try {
      await CloudApiService.saveMessage(
        chatId: cloudChatId,
        role: role,
        content: content,
      );
    } catch (error) {
      debugPrint('No se pudo guardar mensaje cloud: $error');
    }
  }

  Future<void> askQuestion() async {
    final question = questionController.text.trim();

    if (question.isEmpty || isLoading) return;

    fakeStreamTimer?.cancel();

    setState(() {
      isLoading = true;
      errorMessage = '';
      messages.add(
        ChatMessageModel(
          text: question,
          isUser: true,
          createdAt: DateTime.now(),
        ),
      );
    });

    questionController.clear();

    await persistChat();

    unawaited(
      saveCloudMessage(
        role: 'user',
        content: question,
      ),
    );

    try {
      debugPrint('STEP 2: Antes de llamar API');

      final data = isWorkspaceChat
          ? await ApiService.chatWithWorkspace(
              documentIds: effectiveDocumentIds,
              question: question,
              history: buildConversationHistory(),
            )
          : await ApiService.chatWithDocumentId(
              documentId: widget.documentId,
              question: question,
            );

      debugPrint('STEP 3: Respuesta recibida');

      final response = cleanMarkdown(
        data['answer'] ?? l10n.noAnswerReceived,
      );

      final rawCitations = data['citations'];

      final confidence = data['confidence']?.toString();

      final averageDistance = data['average_distance'] is num
          ? (data['average_distance'] as num).toDouble()
          : null;

      final confidenceMessage = data['message']?.toString();

      final citations = rawCitations is List
          ? rawCitations
              .whereType<Map>()
              .map(
                (citation) => ChatCitationModel.fromMap(
                  Map<String, dynamic>.from(citation),
                ),
              )
              .toList()
          : <ChatCitationModel>[];

      setState(() {
        messages.add(
          ChatMessageModel(
            text: '',
            isUser: false,
            createdAt: DateTime.now(),
            isStreaming: true,
            confidence: confidence,
            averageDistance: averageDistance,
            confidenceMessage: confidenceMessage,
            citations: citations,
          ),
        );
      });

      final responseIndex = messages.length - 1;

      for (final character in response.characters) {
        if (!mounted) return;

        setState(() {
          final current = messages[responseIndex];

          messages[responseIndex] = current.copyWith(
            text: current.text + character,
            isStreaming: true,
            confidence: confidence,
            averageDistance: averageDistance,
            confidenceMessage: confidenceMessage,
            citations: citations,
          );
        });

        await Future.delayed(
          const Duration(milliseconds: 5),
        );
      }

      if (!mounted) return;

      setState(() {
        final current = messages[responseIndex];

        messages[responseIndex] = current.copyWith(
          isStreaming: false,
          citations: citations,
        );
      });

      unawaited(
        saveCloudMessage(
          role: 'assistant',
          content: messages[responseIndex].text,
        ),
      );

      await persistChat();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        messages.add(
          ChatMessageModel(
            text: l10n.chatTemporaryError,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      });

      await persistChat();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> renderFakeStreaming(String response) async {
    final completer = Completer<void>();

    final words = response
        .split(RegExp(r'(\s+)'))
        .where((word) => word.isNotEmpty)
        .toList();

    var index = 0;
    var currentText = '';

    setState(() {
      messages.add(
        ChatMessageModel(
          text: '',
          isUser: false,
          createdAt: DateTime.now(),
          isStreaming: true,
        ),
      );
    });

    fakeStreamTimer = Timer.periodic(
      const Duration(milliseconds: 35),
      (timer) {
        if (!mounted) {
          timer.cancel();
          if (!completer.isCompleted) completer.complete();
          return;
        }

        if (index >= words.length) {
          timer.cancel();

          final lastIndex = messages.length - 1;
          final current = messages[lastIndex];

          setState(() {
            messages[lastIndex] = current.copyWith(
              text: currentText.trim(),
              isStreaming: false,
            );
          });

          if (!completer.isCompleted) completer.complete();
          return;
        }

        currentText += '${words[index]} ';

        final lastIndex = messages.length - 1;
        final current = messages[lastIndex];

        setState(() {
          messages[lastIndex] = current.copyWith(
            text: currentText,
            isStreaming: true,
          );
        });

        index++;
      },
    );

    return completer.future;
  }

  Future<void> exportChatToDocx() async {
    if (!const PlanGuardService().canExportDocx) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportChatToWord,
      );
      return;
    }

    final exportableMessages = messages
        .where((message) => message.text.trim().isNotEmpty)
        .map((message) {
      final role = message.isUser ? l10n.userRole : 'StudyBook AI';
      return '$role:\n${message.text.trim()}';
    }).join('\n\n---\n\n');

    if (exportableMessages.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noContentToExport),
        ),
      );

      return;
    }

    try {
      await ExportService.exportTextToDocx(
        title: '${l10n.chatTitlePrefix} - ${widget.fileName}',
        content: exportableMessages,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.chatExportWordError}: $error',
          ),
        ),
      );
    }
  }

  Future<void> exportChatToPdf() async {
    if (!const PlanGuardService().canExportPdf) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportChatToPdf,
      );
      return;
    }

    final exportableMessages = messages
        .where((message) => message.text.trim().isNotEmpty)
        .map((message) {
      final role = message.isUser ? l10n.userRole : 'StudyBook AI';
      return '$role:\n${message.text.trim()}';
    }).join('\n\n---\n\n');

    if (exportableMessages.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noContentToExport),
        ),
      );

      return;
    }

    try {
      await ExportService.exportTextToPdf(
        title: '${l10n.chatTitlePrefix} - ${widget.fileName}',
        content: exportableMessages,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.chatExportPdfError}: $error',
          ),
        ),
      );
    }
  }

  String cleanMarkdown(String text) {
    return text
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('*', '')
        .trim();
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWorkspaceChat
                      ? l10n.workspaceAiChat
                      : l10n.contextualAiChat,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Tooltip(
                  message: widget.fileName,
                  child: Text(
                    widget.fileName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: l10n.exportChatToWord,
            child: IconButton(
              onPressed: exportChatToDocx,
              icon: const Icon(
                Icons.description_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Tooltip(
            message: l10n.exportChatToPdf,
            child: IconButton(
              onPressed: exportChatToPdf,
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContextPanel() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeContext,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.description_rounded,
                  color: AppTheme.accent,
                  size: 32,
                ),
                const SizedBox(height: 14),
                Text(
                  widget.fileName,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isWorkspaceChat
                      ? l10n.workspaceRagContext
                      : l10n.documentRagContext,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ContextHint(
            icon: Icons.tips_and_updates_rounded,
            text: l10n.contextHintConcepts,
          ),
          _ContextHint(
            icon: Icons.school_rounded,
            text: l10n.contextHintAcademic,
          ),
          _ContextHint(
            icon: Icons.fact_check_rounded,
            text: l10n.contextHintSources,
          ),
        ],
      ),
    );
  }

  Widget buildChatContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: buildHeader(),
        ),
        Expanded(
          child: ChatMessages(
            messages: messages,
            isLoading: isLoading,
          ),
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ChatInput(
          controller: questionController,
          isLoading: isLoading,
          onSend: askQuestion,
        ),
      ],
    );
  }

  Widget buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('StudyBook AI'),
      ),
      body: buildChatContent(),
    );
  }

  Widget buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Row(
          children: [
            const Sidebar(
              currentRoute: '/chat',
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 920,
                  ),
                  child: buildChatContent(),
                ),
              ),
            ),
            buildContextPanel(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: buildMobileLayout(),
      tablet: buildMobileLayout(),
      desktop: buildDesktopLayout(),
    );
  }
}

class _ContextHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContextHint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
