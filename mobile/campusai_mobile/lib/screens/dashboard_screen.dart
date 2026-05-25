import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../models/document_history.dart';
import '../providers/document_provider.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/dashboard/dashboard_hero.dart';
import '../widgets/dashboard/dashboard_stats.dart';
import '../widgets/dashboard/dashboard_tools.dart';
import '../widgets/dashboard/history_list.dart';
import '../widgets/mini_player.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard/modules/dashboard_audio_section.dart';
import '../widgets/dashboard/modules/dashboard_error_card.dart';
import '../widgets/dashboard/modules/dashboard_processing_card.dart';
import '../widgets/dashboard/modules/dashboard_summary_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AudioPlayerService audioService = AudioPlayerService();

  bool isLoading = false;
  bool isPlaying = false;

  String documentId = '';
  String summary = '';
  String audioUrl = '';
  String fileName = '';
  String errorMessage = '';

  List<DocumentHistory> history = [];

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  String get fullAudioUrl => ApiService.buildAudioUrl(audioUrl);

  bool get hasActiveDocument => documentId.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    initializeDashboard();

    audioService.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => currentPosition = position);
    });

    audioService.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => totalDuration = duration ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    audioService.dispose();
    super.dispose();
  }

  Future<void> initializeDashboard() async {
    await loadHistory();
    await restoreActiveDocument();
  }

  Future<void> restoreActiveDocument() async {
    final activeDocument = await HistoryService.getActiveDocument();

    if (activeDocument == null || !mounted) return;

    setState(() {
      documentId = activeDocument.documentId;
      summary = activeDocument.summary;
      audioUrl = activeDocument.audioUrl;
      fileName = activeDocument.fileName;
      errorMessage = '';
    });

    await ref.read(activeDocumentProvider.notifier).setDocument(activeDocument);
  }

  Future<void> loadHistory() async {
    final data = await HistoryService.getHistory();

    if (!mounted) return;

    setState(() {
      history = data;
    });
  }

  Future<void> uploadPdf() async {
    setState(() {
      isLoading = true;
      isPlaying = false;
      documentId = '';
      summary = '';
      audioUrl = '';
      fileName = '';
      errorMessage = '';
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
    });

    try {
      final data = await ApiService.uploadPdf();
      debugPrint('UPLOAD RESPONSE: $data');

      final document = DocumentHistory(
        documentId: data['document_id'] ?? '',
        fileName: data['file_name'] ?? data['filename'] ?? 'Documento PDF',
        summary: data['ai_summary'] ?? 'No se recibió resumen.',
        audioUrl: data['audio_url'] ?? '',
        createdAt: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      setState(() {
        documentId = document.documentId;
        summary = document.summary;
        audioUrl = document.audioUrl;
        fileName = document.fileName;
      });

      await HistoryService.saveDocument(document);
      await HistoryService.saveActiveDocument(document);
      await ref.read(activeDocumentProvider.notifier).setDocument(document);
      await loadHistory();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> playAudio() async {
    if (fullAudioUrl.isEmpty) return;

    try {
      await audioService.play(fullAudioUrl);

      if (!mounted) return;

      setState(() {
        isPlaying = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo reproducir el audio: $error';
      });
    }
  }

  Future<void> pauseAudio() async {
    await audioService.pause();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
    });
  }

  Future<void> replayAudio() async {
    if (fullAudioUrl.isEmpty) return;

    try {
      await audioService.replay();

      if (!mounted) return;

      setState(() {
        isPlaying = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo reiniciar el audio: $error';
      });
    }
  }

  Future<void> loadHistoryItem(DocumentHistory item) async {
    await pauseAudio();

    if (!mounted) return;

    setState(() {
      documentId = item.documentId;
      summary = item.summary;
      audioUrl = item.audioUrl;
      fileName = item.fileName;
      errorMessage = '';
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
      isPlaying = false;
    });

    await HistoryService.saveActiveDocument(item);
    await ref.read(activeDocumentProvider.notifier).setDocument(item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Documento cargado: ${item.fileName}')),
    );
  }

  Future<void> deleteHistoryItem(int index) async {
    await HistoryService.deleteDocument(index);
    await loadHistory();

    final activeDocument = await HistoryService.getActiveDocument();

    if (!mounted) return;

    if (activeDocument == null) {
      setState(() {
        documentId = '';
        summary = '';
        audioUrl = '';
        fileName = '';
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        isPlaying = false;
      });

      await ref.read(activeDocumentProvider.notifier).clearDocument();
    } else {
      setState(() {
        documentId = activeDocument.documentId;
        summary = activeDocument.summary;
        audioUrl = activeDocument.audioUrl;
        fileName = activeDocument.fileName;
      });

      await ref.read(activeDocumentProvider.notifier).setDocument(activeDocument);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documento eliminado del historial.')),
    );
  }

  Future<void> clearAllHistory() async {
    await HistoryService.clearHistory();
    await ref.read(activeDocumentProvider.notifier).clearDocument();
    await pauseAudio();

    if (!mounted) return;

    setState(() {
      history = [];
      documentId = '';
      summary = '';
      audioUrl = '';
      fileName = '';
      errorMessage = '';
      currentPosition = Duration.zero;
      totalDuration = Duration.zero;
      isPlaying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial eliminado.')),
    );
  }

  void showNoActiveDocumentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Primero sube o selecciona un documento.')),
    );
  }

  void openChatScreen() {
    if (!hasActiveDocument) {
      showNoActiveDocumentMessage();
      return;
    }

    context.pushNamed(
      'chat',
      pathParameters: {'documentId': documentId},
      queryParameters: {'fileName': fileName.isEmpty ? 'Documento activo' : fileName},
    );
  }

  void openExamScreen() {
    if (!hasActiveDocument) {
      showNoActiveDocumentMessage();
      return;
    }

    context.pushNamed(
      'exam',
      pathParameters: {'documentId': documentId},
    );
  }

  void openFlashcardsScreen() {
    if (!hasActiveDocument) {
      showNoActiveDocumentMessage();
      return;
    }

    context.pushNamed(
      'flashcards',
      pathParameters: {'documentId': documentId},
    );
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  String cleanMarkdown(String text) {
    return text
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('__', '')
        .trim();
  }

  Widget buildDashboardBody({
  required bool effectiveHasActiveDocument,
  required String effectiveFileName,
}) {
  return ListView(
    padding: const EdgeInsets.all(22),
    children: [
      AnimatedFadeSlide(
        child: DashboardHero(
          documentCount: history.length,
          hasActiveDocument: effectiveHasActiveDocument,
        ),
      ),
      const SizedBox(height: 18),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 80),
        child: DashboardStats(
          documentCount: history.length,
          hasActiveDocument: effectiveHasActiveDocument,
        ),
      ),
      const SizedBox(height: 28),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 160),
        child: DashboardTools(
          isLoading: isLoading,
          hasActiveDocument: effectiveHasActiveDocument,
          uploadPdf: uploadPdf,
          openChat: openChatScreen,
          openExam: openExamScreen,
          openFlashcards: openFlashcardsScreen,
        ),
      ),
      const SizedBox(height: 22),

      DashboardErrorCard(
          errorMessage: errorMessage,
        ),

      if (errorMessage.isNotEmpty) const SizedBox(height: 20),

      if (isLoading) ...[
        const DashboardProcessingCard(),
        const SizedBox(height: 24),
      ],

      if (!isLoading) ...[
        DashboardSummarySection(
          summary: summary,
        ),
        if (summary.isNotEmpty) const SizedBox(height: 24),
        DashboardAudioSection(
          fileName: fileName,
          fullAudioUrl: fullAudioUrl,
          isPlaying: isPlaying,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          onPlayPause: isPlaying ? pauseAudio : playAudio,
          onReplay: replayAudio,
          onSeek: (value) {
            audioService.seek(
              Duration(seconds: value.toInt()),
            );
          },
        ),
        if (fullAudioUrl.isNotEmpty) const SizedBox(height: 28),
      ],

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 320),
        child: HistoryList(
          history: history,
          clearHistory: clearAllHistory,
          loadDocument: loadHistoryItem,
          deleteDocument: deleteHistoryItem,
        ),
      ),

      const SizedBox(height: 24),
      const MiniPlayer(),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    final activeDocument = ref.watch(activeDocumentProvider);

    final effectiveDocumentId = activeDocument?.documentId ?? documentId;
    final effectiveFileName = activeDocument?.fileName ?? fileName;
    final effectiveHasActiveDocument = effectiveDocumentId.trim().isNotEmpty;

    final dashboardContent = buildDashboardBody(
      effectiveHasActiveDocument: effectiveHasActiveDocument,
      effectiveFileName: effectiveFileName,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: dashboardContent,
          tablet: dashboardContent,
          desktop: Row(
            children: [
              const Sidebar(currentRoute: '/dashboard'),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: dashboardContent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
