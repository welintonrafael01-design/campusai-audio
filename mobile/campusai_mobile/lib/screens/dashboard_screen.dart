import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../l10n/app_localizations.dart';
import '../models/document_history.dart';
import '../models/recent_document_model.dart';
import '../models/study_result.dart';
import '../models/workspace_model.dart';
import '../providers/document_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/history_service.dart';
import '../services/onboarding_service.dart';
import '../services/plan_guard_service.dart';
import '../services/recent_documents_service.dart';
import '../services/subscription_service.dart';
import '../services/study_result_service.dart';
import '../services/workspace_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/dashboard/dashboard_hero.dart';
import '../widgets/dashboard/dashboard_stats.dart';
import '../widgets/dashboard/dashboard_academic_activity.dart';
import '../widgets/dashboard/dashboard_tools.dart';
import '../widgets/dashboard/dashboard_educator_center.dart';
import '../widgets/dashboard/history_list.dart';
import '../widgets/dashboard/recent_documents_panel.dart';
import '../widgets/dashboard/workspaces_panel.dart';
import '../widgets/dashboard/cloud_chats_panel.dart';
import '../widgets/mini_player.dart';
import '../widgets/onboarding/studybook_onboarding_dialog.dart';
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

  AppLocalizations get l10n => AppLocalizations.of(context);

  String _dashboardUserName() {
    final metadata = AuthService.currentUser?.userMetadata ?? {};
    final fullName = (metadata['full_name'] ??
            metadata['name'] ??
            metadata['display_name'])
        ?.toString()
        .trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName.split(' ').first;
    }

    final email = AuthService.currentUser?.email?.trim() ?? '';

    if (email.toLowerCase().startsWith('welintonrafael01')) {
      return 'Welinton';
    }

    if (email.toLowerCase().startsWith('cruzgeraldoc24')) {
      return 'Cruz';
    }

    final rawName = email.split('@').first.replaceAll('.', ' ').trim();

    if (rawName.isEmpty) {
      return 'Estudiante';
    }

    return rawName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final clean = part.trim();
          return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
        })
        .join(' ');
  }


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
    await handleCheckoutReturn();
    await checkOnboarding();

    await Future.wait([
      loadHistory(),
      loadRecentDocuments(),
      loadWorkspaces(),
      restoreActiveDocument(),
    ]);
  }

  Future<void> handleCheckoutReturn() async {
    String? checkoutStatus;
    String? planCode;

    try {
      final uri = GoRouterState.of(context).uri;
      checkoutStatus = uri.queryParameters['checkout'];
      planCode = uri.queryParameters['plan'];
    } catch (_) {
      checkoutStatus = Uri.base.queryParameters['checkout'];
      planCode = Uri.base.queryParameters['plan'];
    }

    if (checkoutStatus != 'success') return;

    await syncSubscriptionPlan();

    if (!mounted) return;

    final cleanPlan = (planCode ?? '').trim().toUpperCase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleanPlan.isEmpty
              ? 'Plan actualizado correctamente.'
              : 'Plan $cleanPlan activado correctamente.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.go('/dashboard');
  }

  Future<void> checkOnboarding() async {
    final shouldShow = await const OnboardingService().shouldShowOnboarding();

    if (!shouldShow || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StudyBookOnboardingDialog(),
    );
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.uploadAtLeastOneDocument,
          ),
        ),
      );
      return;
    }

    final draft = await showDialog<_WorkspaceDraft>(
      context: context,
      builder: (_) {
        return _CreateWorkspaceDialog(
          documents: recentDocuments,
        );
      },
    );

    if (!mounted || draft == null) return;

    final selectedDocuments = recentDocuments
        .where(
          (document) => draft.documentIds.contains(
            document.documentId,
          ),
        )
        .toList();

    if (selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.selectAtLeastOneDocument,
          ),
        ),
      );
      return;
    }

    String workspaceId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final cloudWorkspace = await CloudApiService.createWorkspace(
        name: draft.name,
        description: l10n.workspaceCreatedFromStudyBook,
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
      name: draft.name,
      documents: selectedDocuments,
      updatedAt: DateTime.now(),
    );

    await WorkspaceService.saveWorkspace(workspace);
    await loadWorkspaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workspace "${draft.name}" creado con ${selectedDocuments.length} documento(s).',
        ),
      ),
    );
  }

  Future<void> openCloudChat(Map<String, dynamic> chat) async {
    final chatId = chat['id'] ?? '';
    final documentId = chat['document_id'] ?? '';
    final title = chat['title'] ?? l10n.cloudConversation;

    if (chatId.toString().isEmpty || documentId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.conversationWithoutDocument,
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
        SnackBar(
          content: Text(l10n.workspaceWithoutDocuments),
        ),
      );
      return;
    }

    final firstDocument = workspace.documents.first;

    final workspaceDocumentIds = workspace.documents
        .map((item) => item.documentId)
        .where((item) => item.trim().isNotEmpty)
        .toList();

    if (workspaceDocumentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.workspaceWithoutValidDocuments,
          ),
        ),
      );
      return;
    }

    ref
        .read(activeWorkspaceProvider.notifier)
        .setWorkspaceDocuments(workspaceDocumentIds);

    context.pushNamed(
      'chat',
      pathParameters: {
        'documentId': firstDocument.documentId,
      },
      queryParameters: {
        'fileName': workspace.name,
        'workspaceId': workspace.workspaceId,
        'workspaceIds': workspaceDocumentIds.join(','),
      },
    );
  }

  List<String> workspaceDocumentIdsFrom(WorkspaceModel workspace) {
    return workspace.documents
        .map((item) => item.documentId)
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> parseWorkspaceGeneratedList(
    dynamic raw,
    String key,
  ) {
    dynamic decoded = raw;

    if (raw is String) {
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      decoded = jsonDecode(clean);
    }

    if (decoded is Map<String, dynamic>) {
      final list =
          decoded[key] ?? decoded['questions'] ?? decoded['flashcards'];

      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Future<void> openWorkspaceFlashcards(WorkspaceModel workspace) async {
    final documentIds = workspaceDocumentIdsFrom(workspace);

    if (documentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workspaceWithoutValidDocuments),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando flashcards del workspace...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final data = await ApiService.generateWorkspaceFlashcards(
        documentIds: documentIds,
        numberOfCards: 20,
      );

      final parsed = parseWorkspaceGeneratedList(
        data['flashcards'],
        'flashcards',
      );

      if (parsed.isEmpty) {
        throw Exception('La IA generó una respuesta vacía o no válida.');
      }

      final workspaceResultId = 'workspace_${workspace.workspaceId}_flashcards';
      final content = jsonEncode(parsed);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: workspaceResultId,
          type: 'flashcards',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: workspaceResultId,
          type: 'flashcards',
          content: content,
        );
      } catch (cloudError) {
        debugPrint(
            'No se pudo guardar flashcards workspace cloud: $cloudError');
      }

      if (!mounted) return;

      context.pushNamed(
        'flashcards',
        pathParameters: {
          'documentId': workspaceResultId,
        },
        extra: parsed,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron generar flashcards: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openWorkspaceExam(WorkspaceModel workspace) async {
    final documentIds = workspaceDocumentIdsFrom(workspace);

    if (documentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.workspaceWithoutValidDocuments),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando examen del workspace...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final data = await ApiService.generateWorkspaceExam(
        documentIds: documentIds,
        numberOfQuestions: 20,
      );

      final parsed = parseWorkspaceGeneratedList(
        data['questions'] ?? data['exam'],
        'questions',
      );

      if (parsed.isEmpty) {
        throw Exception('La IA generó una respuesta vacía o no válida.');
      }

      final workspaceResultId = 'workspace_${workspace.workspaceId}_exam';
      final content = jsonEncode(parsed);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: workspaceResultId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: workspaceResultId,
          type: 'exam',
          content: content,
        );
      } catch (cloudError) {
        debugPrint('No se pudo guardar examen workspace cloud: $cloudError');
      }

      if (!mounted) return;

      context.pushNamed(
        'exam',
        pathParameters: {
          'documentId': workspaceResultId,
        },
        extra: parsed,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el examen: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> renameWorkspace(WorkspaceModel workspace) async {
    final controller = TextEditingController(text: workspace.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Renombrar workspace'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del workspace',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (!mounted || newName == null || newName.trim().isEmpty) return;

    final updatedWorkspace = WorkspaceModel(
      workspaceId: workspace.workspaceId,
      name: newName.trim(),
      documents: workspace.documents,
      updatedAt: DateTime.now(),
    );

    await WorkspaceService.updateWorkspace(updatedWorkspace);

    try {
      await CloudApiService.updateWorkspace(
        workspaceId: workspace.workspaceId,
        name: newName.trim(),
        description: l10n.workspaceCreatedFromStudyBook,
      );
    } catch (error) {
      debugPrint('No se pudo renombrar workspace cloud: $error');
    }

    await loadWorkspaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Workspace renombrado a "$newName".'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> removeDocumentFromWorkspace(
    WorkspaceModel workspace,
    String documentId,
  ) async {
    if (workspace.documents.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El workspace debe conservar al menos un documento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedDocuments = workspace.documents
        .where((document) => document.documentId != documentId)
        .toList();

    final updatedWorkspace = WorkspaceModel(
      workspaceId: workspace.workspaceId,
      name: workspace.name,
      documents: updatedDocuments,
      updatedAt: DateTime.now(),
    );

    await WorkspaceService.updateWorkspace(updatedWorkspace);
    await loadWorkspaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Documento removido de "${workspace.name}".',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> addDocumentsToWorkspace(WorkspaceModel workspace) async {
    final existingIds = workspace.documents
        .map((item) => item.documentId)
        .where((item) => item.trim().isNotEmpty)
        .toSet();

    final availableDocuments = recentDocuments
        .where((document) => !existingIds.contains(document.documentId))
        .toList();

    if (availableDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay documentos nuevos disponibles para agregar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final draft = await showDialog<_WorkspaceDraft>(
      context: context,
      builder: (_) {
        return _CreateWorkspaceDialog(
          documents: availableDocuments,
        );
      },
    );

    if (!mounted || draft == null) return;

    final selectedDocuments = availableDocuments
        .where((document) => draft.documentIds.contains(document.documentId))
        .toList();

    if (selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneDocument),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedWorkspace = WorkspaceModel(
      workspaceId: workspace.workspaceId,
      name: workspace.name,
      documents: [
        ...workspace.documents,
        ...selectedDocuments,
      ],
      updatedAt: DateTime.now(),
    );

    await WorkspaceService.updateWorkspace(updatedWorkspace);

    for (final document in selectedDocuments) {
      try {
        await CloudApiService.createDocument(
          workspaceId: workspace.workspaceId,
          documentName: document.fileName,
          documentId: document.documentId,
        );
      } catch (error) {
        debugPrint(
          'No se pudo sincronizar documento agregado al workspace: $error',
        );
      }
    }

    await loadWorkspaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedDocuments.length} documento(s) agregado(s) a "${workspace.name}".',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deleteWorkspace(WorkspaceModel workspace) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar workspace'),
        content: Text(
          'Se eliminará "${workspace.name}" y su relación con los documentos y chats cloud asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await WorkspaceService.removeWorkspace(workspace.workspaceId);

    try {
      await CloudApiService.deleteWorkspace(
        workspaceId: workspace.workspaceId,
      );
    } catch (error) {
      debugPrint('No se pudo eliminar workspace cloud: $error');
    }

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
        fileName: data['file_name'] ??
            data['filename'] ??
            l10n.defaultPdfDocumentName,
        summary: data['ai_summary'] ?? l10n.summaryNotReceived,
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

      final generatedAudioUrl = data['audio_url'] ?? '';

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
        errorMessage = '${l10n.audioGenerationErrorPrefix}: $error';
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
        errorMessage = '${l10n.audioPlaybackErrorPrefix}: $error';
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
        errorMessage = '${l10n.audioReplayErrorPrefix}: $error';
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
      SnackBar(content: Text('${l10n.documentLoaded}: ${item.fileName}')),
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

      await ref
          .read(activeDocumentProvider.notifier)
          .setDocument(activeDocument);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.documentDeletedFromHistory)),
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
      SnackBar(content: Text(l10n.historyDeleted)),
    );
  }

  void openSemanticSearchDocument(String selectedDocumentId) {
    context.pushNamed(
      'chat',
      pathParameters: {
        'documentId': selectedDocumentId,
      },
      queryParameters: {
        'fileName': l10n.searchResult,
      },
    );
  }

  void showNoActiveDocumentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.uploadOrSelectDocumentFirst)),
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
      queryParameters: {
        'fileName': fileName.isEmpty ? l10n.activeDocument : fileName
      },
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
    final isMobile = ResponsiveLayout.isMobile(context);

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      children: [
        AnimatedFadeSlide(
          child: DashboardHero(
            documentCount: history.length,
            hasActiveDocument: effectiveHasActiveDocument,
            userName: _dashboardUserName(),
            planName: const PlanGuardService().currentPlanName,
            activeFileName: effectiveFileName,
            onContinueStudy: openChatScreen,
            onUploadPdf: uploadPdf,
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
        SizedBox(height: isMobile ? 22 : 28),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 120),
          child: DashboardAcademicActivity(
            workspaceCount: workspaces.length,
            workspaceDocumentCount: workspaces.fold<int>(
              0,
              (total, workspace) => total + workspace.documents.length,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 22 : 28),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 150),
          child: DashboardEducatorCenter(
            hasActiveDocument: effectiveHasActiveDocument,
            openExam: openExamScreen,
            openFlashcards: openFlashcardsScreen,
          ),
        ),
        SizedBox(height: isMobile ? 22 : 28),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 190),
          child: DashboardTools(
            isLoading: isLoading,
            hasActiveDocument: effectiveHasActiveDocument,
            uploadPdf: uploadPdf,
            openChat: openChatScreen,
            openExam: openExamScreen,
            openFlashcards: openFlashcardsScreen,
            openAudiobook: generateAudio,
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
            onListenSummary: generateAudio,
            onVoiceChat: openChatScreen,
            isGeneratingAudio: isGeneratingAudio,
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
            onWorkspaceFlashcards: openWorkspaceFlashcards,
            onWorkspaceExam: openWorkspaceExam,
            onOpenChat: openCloudChat,
            onAddDocuments: addDocumentsToWorkspace,
            onRenameWorkspace: renameWorkspace,
            onRemoveDocument: removeDocumentFromWorkspace,
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
      drawer: const Drawer(
        backgroundColor: AppTheme.surface,
        child: Sidebar(currentRoute: '/dashboard'),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: Builder(
            builder: (context) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Menú',
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'StudyBook AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: dashboardContent),
                ],
              );
            },
          ),
          tablet: Row(
            children: [
              const Sidebar(currentRoute: '/dashboard'),
              Expanded(child: dashboardContent),
            ],
          ),
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

class _WorkspaceDraft {
  final String name;
  final Set<String> documentIds;

  const _WorkspaceDraft({
    required this.name,
    required this.documentIds,
  });
}

class _CreateWorkspaceDialog extends StatefulWidget {
  final List<RecentDocumentModel> documents;

  const _CreateWorkspaceDialog({
    required this.documents,
  });

  @override
  State<_CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<_CreateWorkspaceDialog> {
  late final TextEditingController nameController;
  final Set<String> selectedDocumentIds = {};

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (nameController.text.trim().isEmpty) {
      nameController.text = AppLocalizations.of(context).myWorkspace;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameController.text.trim();

    if (name.isEmpty || selectedDocumentIds.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _WorkspaceDraft(
        name: name,
        documentIds: Set<String>.from(
          selectedDocumentIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        nameController.text.trim().isNotEmpty && selectedDocumentIds.isNotEmpty;

    return AlertDialog(
      title: Text(AppLocalizations.of(context).createWorkspace),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).workspaceName,
                  hintText: AppLocalizations.of(context).workspaceNameHint,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(context).selectDocuments,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.documents.map((document) {
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
                    setState(() {
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
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: canCreate ? submit : null,
          child: Text(AppLocalizations.of(context).create),
        ),
      ],
    );
  }
}
