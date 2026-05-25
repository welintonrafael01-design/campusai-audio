import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../models/chat_message_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/chat_messages.dart';
import '../widgets/sidebar.dart';

class ChatScreen extends StatefulWidget {
  final String documentId;
  final String fileName;

  const ChatScreen({
    super.key,
    required this.documentId,
    required this.fileName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController questionController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  final List<ChatMessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  void initializeChat() {
    messages.add(
      ChatMessageModel(
        text:
            'Hola. Soy StudyBook AI.\n\nEstoy listo para ayudarte a comprender el documento "${widget.fileName}".\n\nPuedes hacer preguntas, pedir explicaciones, resúmenes, conceptos clave o análisis académicos.',
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  Future<void> askQuestion() async {
    final question = questionController.text.trim();

    if (question.isEmpty || isLoading) return;

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

    try {
      final data = await ApiService.chatWithDocumentId(
        documentId: widget.documentId,
        question: question,
      );

      final response = cleanMarkdown(
        data['answer'] ?? 'No se recibió respuesta.',
      );

      if (!mounted) return;

      setState(() {
        messages.add(
          ChatMessageModel(
            text: response,
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        messages.add(
          ChatMessageModel(
            text:
                'No pude responder en este momento.\n\nVerifica la conexión con el backend o intenta nuevamente.',
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                const Text(
                  'Chat IA contextual',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ],
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
          const Text(
            'Contexto activo',
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
                const Text(
                  'RAG activo para responder con base en el documento seleccionado.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ContextHint(
            icon: Icons.tips_and_updates_rounded,
            text: 'Puedes pedir conceptos clave, explicación simple o resumen.',
          ),
          const _ContextHint(
            icon: Icons.school_rounded,
            text: 'También puedes solicitar análisis académico del contenido.',
          ),
          const _ContextHint(
            icon: Icons.fact_check_rounded,
            text: 'Las respuestas se basan en el documento activo.',
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