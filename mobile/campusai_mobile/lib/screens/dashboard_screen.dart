import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../models/document_history.dart';
import '../models/recent_document_model.dart';
import '../models/workspace_model.dart';
import '../providers/document_provider.dart';
import '../services/api_service.dart';
import '../services/cloud_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/history_service.dart';
import '../services/recent_documents_service.dart';
import '../services/subscription_service.dart';
import '../services/workspace_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/dashboard/dashboard_hero.dart';
import '../widgets/dashboard/dashboard_stats.dart';
import '../widgets/dashboard/dashboard_tools.dart';
import '../widgets/dashboard/history_list.dart';
import '../widgets/dashboard/recent_documents_panel.dart';
import '../widgets/dashboard/workspaces_panel.dart';
import '../widgets/dashboard/cloud_chats_panel.dart';
import '../widgets/mini_player.dart';
import '../widgets/sidebar.dart';
import '../widgets/search/semantic_search_panel.dart';
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
  bool isGeneratingAudio = false;

  String documentId = '';
  String summary = '';
  String audioUrl = '';
  String fileName = '';
  String errorMessage = '';

  List<DocumentHistory> history = [];
  List<RecentDocumentModel> recentDocuments = [];
  List<WorkspaceModel> workspaces = [];

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  String get fullAudioUrl => ApiService.buildAudioUrl(audioUrl);

  bool get hasActiveDocument => documentId.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeDashboard();
    });

    audioService.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => currentPosition = position);
    });

    audioService.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => totalDuration = duration ?? Duration.zero);
    });

    audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    audioService.dispose();
    super.dispose();
  }

  Future<void> initializeDashboard() async {
    await syncSubscriptionPlan();

    await Future.wait([
      loadHistory(),
      loadRecentDocuments(),
      loadWorkspaces(),
      restoreActiveDocument(),
    ]);
  }

  Future<void> syncSubscriptionPlan() async {
    try {
      await const SubscriptionService().syncCurrentUserPlan();
    } catch (error) {
      debugPrint('No se pudo sincronizar el plan: $error');
    }
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

  Future<void> loadRecentDocuments() async {
    final documents = await RecentDocumentsService.getDocuments();

    if (!mounted) return;

    setState(() {
      recentDocuments = documents;
    });
  }


  Future<void> loadWorkspaces() async {
    final data = await WorkspaceService.getWorkspaces();

    if (!mounted) return;

    setState(() {
      workspaces = data;
    });
  }

  Future<void> createWorkspace() async {
    if (recentDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero debes subir al menos un documento.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController(
      text: 'Mi workspace',
    );

    final selectedDocumentIds = <String>{};

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear workspace'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del workspace',
                          hintText: 'Ej.: Tesis, Derecho Penal, Proyecto final',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Selecciona documentos',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recentDocuments.map((document) {
                        final isSelected = selectedDocumentIds.contains(
                          document.documentId,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            document.fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedDocumentIds.add(
                                  document.documentId,
                                );
                              } else {
                                selectedDocumentIds.remove(
                                  document.documentId,
                                );
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selectedDocumentIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(true);
                        },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true) {
      nameController.dispose();
      return;
    }

    final workspaceName = nameController.text.trim();

    nameController.dispose();

    if (workspaceName.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre del workspace no puede estar vacío.',
          ),
        ),
      );
      return;
    }

    final selectedDocuments = recentDocuments
        .where(
          (document) => selectedDocumentIds.contains(
            document.documentId,
          ),
        )
        .toList();

    if (selectedDocuments.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un documento.',
          ),
        ),
      );
      return;
    }

    String workspaceId =
        DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final cloudWorkspace =
          await CloudApiService.createWorkspace(
        name: workspaceName,
        description: 'Workspace creado desde StudyBook AI',
      );

      workspaceId = cloudWorkspace['id'] ?? workspaceId;

      for (final document in selectedDocuments) {
        try {
          await CloudApiService.createDocument(
            workspaceId: workspaceId,
            documentName: document.fileName,
            documentId: document.documentId,
          );
        } catch (error) {
          debugPrint(
            'No se pudo sincronizar documento cloud: $error',
          );
        }
      }
    } catch (error) {
      debugPrint('No se pudo sincronizar workspace cloud: $error');
    }

    final workspace = WorkspaceModel(
      workspaceId: workspaceId,
      name: workspaceName,
      documents: selectedDocuments,
      updatedAt: DateTime.now(),
    );

    await WorkspaceService.saveWorkspace(workspace);
    await loadWorkspaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workspace "$workspaceName" creado con ${selectedDocuments.length} documento(s).',
        ),
      ),
    );
  }

  Future<void> openCloudChat(Map<String, dynamic> chat) async {
    final chatId = chat['id'] ?? '';
    final documentId = chat['document_id'] ?? '';
    final title = chat['title'] ?? 'Conversación cloud';

    if (chatId.toString().isEmpty ||
        documentId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta conversación no tiene documento asociado.',
          ),
        ),
      );
      return;
    }

    context.pushNamed(
      'chat',
      pathParameters: {
        'documentId': documentId.toString(),
      },
      queryParameters: {
        'fileName': title.toString(),
        'cloudChatId': chatId.toString(),
      },
    );
  }

  Future<void> openWorkspace(WorkspaceModel workspace) async {
    if (workspace.documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este workspace no tiene documentos.'),
        ),
      );
      return;
    }

    final firstDocument = workspace.documents.first;

    await openRecentDocument(firstDocument);

    if (!mounted) return;

    final workspaceDocumentIds = workspace.documents
        .map((item) => item.documentId)
        .toList();

    ref
        .read(activeWorkspaceProvider.notifier)
        .setWorkspaceDocuments(workspaceDocumentIds);

    context.pushNamed(
      'chat',
      pathParameters: {
        'documentId': firstDocument.documentId,
      },
      queryParameters: {
        'fileName': firstDocument.fileName,
      },
    );
  }

  Future<void> deleteWorkspace(WorkspaceModel workspace) async {
    await WorkspaceService.removeWorkspace(workspace.workspaceId);
    await loadWorkspaces();
  }

  Future<void> loadHistory() async {
    final data = await HistoryService.getHistory();

    if (!mounted) return;

    setState(() {
      history = data;
    });
  }

  Future<void> uploadPdf() async {
    await audioService.reset();

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
      await RecentDocumentsService.saveDocument(
        RecentDocumentModel(
          documentId: document.documentId,
          fileName: document.fileName,
          summary: document.summary,
          audioUrl: document.audioUrl,
          lastOpenedAt: DateTime.now(),
        ),
      );
      await ref.read(activeDocumentProvider.notifier).setDocument(document);
      await loadHistory();
    await loadRecentDocuments();
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

  Future<void> generateAudio() async {
    if (summary.trim().isEmpty || isGeneratingAudio) return;

    setState(() {
      isGeneratingAudio = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.generateAudioFromText(
        text: summary,
      );

      if (!mounted) return;

      final generatedAudioUrl =
          data['audio_url'] ?? '';

      setState(() {
        audioUrl = generatedAudioUrl;
      });

      if (generatedAudioUrl.isNotEmpty) {
        await audioService.preload(
          ApiService.buildAudioUrl(
            generatedAudioUrl,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo generar el audio: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingAudio = false;
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
        isPlaying = audioService.isPlaying;
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
      isPlaying = audioService.isPlaying;
    });
  }

  Future<void> replayAudio() async {
    if (fullAudioUrl.isEmpty) return;

    try {
      await audioService.replay();

      if (!mounted) return;

      setState(() {
        isPlaying = audioService.isPlaying;
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
    await RecentDocumentsService.saveDocument(
      RecentDocumentModel(
        documentId: item.documentId,
        fileName: item.fileName,
        summary: item.summary,
        audioUrl: item.audioUrl,
        lastOpenedAt: DateTime.now(),
      ),
    );
    await ref.read(activeDocumentProvider.notifier).setDocument(item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Documento cargado: ${item.fileName}')),
    );
  }

  Future<void> openRecentDocument(
    RecentDocumentModel document,
  ) async {
    final historyItem = DocumentHistory(
      documentId: document.documentId,
      fileName: document.fileName,
      summary: document.summary,
      audioUrl: document.audioUrl,
      createdAt: document.lastOpenedAt.toIso8601String(),
    );

    await HistoryService.saveActiveDocument(historyItem);
    await RecentDocumentsService.saveDocument(
      document.copyWith(
        lastOpenedAt: DateTime.now(),
      ),
    );

    await ref.read(activeDocumentProvider.notifier).setDocument(historyItem);

    if (!mounted) return;

    setState(() {
      documentId = document.documentId;
      fileName = document.fileName;
      summary = document.summary;
      audioUrl = document.audioUrl;
    });

    await loadRecentDocuments();
  }

  Future<void> deleteRecentDocument(
    RecentDocumentModel document,
  ) async {
    await RecentDocumentsService.removeDocument(document.documentId);

    final currentWorkspaces = await WorkspaceService.getWorkspaces();

    for (final workspace in currentWorkspaces) {
      final updatedDocuments = workspace.documents
          .where((item) => item.documentId != document.documentId)
          .toList();

      await WorkspaceService.saveWorkspace(
        WorkspaceModel(
          workspaceId: workspace.workspaceId,
          name: workspace.name,
          documents: updatedDocuments,
          updatedAt: DateTime.now(),
        ),
      );
    }

    await loadRecentDocuments();
    await loadWorkspaces();
  }

  Future<void> deleteHistoryItem(int index) async {
    await HistoryService.deleteDocument(index);
    await loadHistory();
    await loadRecentDocuments();

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

  void openSemanticSearchDocument(String selectedDocumentId) {
    context.pushNamed(
      'chat',
      pathParameters: {
        'documentId': selectedDocumentId,
      },
      queryParameters: {
        'fileName': 'Resultado de búsqueda',
      },
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
          isGeneratingAudio: isGeneratingAudio,
          hasSummary: summary.trim().isNotEmpty,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          onGenerateAudio: generateAudio,
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
        delay: const Duration(milliseconds: 240),
        child: SemanticSearchPanel(
          onOpenDocument: openSemanticSearchDocument,
        ),
      ),

      const SizedBox(height: 24),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 280),
        child: WorkspacesPanel(
          workspaces: workspaces,
          onCreateWorkspace: createWorkspace,
          onOpenWorkspace: openWorkspace,
          onDeleteWorkspace: deleteWorkspace,
        ),
      ),

      const SizedBox(height: 24),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 320),
        child: RecentDocumentsPanel(
          documents: recentDocuments,
          onOpen: openRecentDocument,
          onDelete: deleteRecentDocument,
        ),
      ),

      const SizedBox(height: 24),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 340),
        child: CloudChatsPanel(
          onOpenChat: openCloudChat,
        ),
      ),

      const SizedBox(height: 24),

      AnimatedFadeSlide(
        delay: const Duration(milliseconds: 360),
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
