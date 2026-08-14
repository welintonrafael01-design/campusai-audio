import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_history.dart';
import '../models/audiobook_history.dart';
import '../models/study_result.dart';
import '../providers/audio_provider.dart';
import '../services/history_service.dart';
import '../services/api_service.dart';
import '../services/audiobook_service.dart';
import '../services/audiobook_library_service.dart';
import '../services/cloud_api_service.dart';
import '../services/library_favorites_service.dart';
import '../services/chat_history_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/mini_player.dart';
import '../widgets/studybook_app_shell.dart';
import '../widgets/studybook/studybook_states.dart';

enum LibrarySortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
}

enum LibrarySourceFilter {
  all,
  local,
  cloud,
}

enum LibraryCategory {
  all,
  documents,
  generated,
  audiobooks,
  chats,
  favorites,
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<DocumentHistory> documents = [];
  List<AudiobookHistory> audiobooks = [];
  final Set<String> cloudDocumentIds = {};
  final Set<String> cloudAudiobookIds = {};
  final Set<String> favoriteDocumentIds = {};
  List<_LibraryChatItem> savedChats = [];
  List<_LibraryGeneratedItem> generatedItems = [];
  LibraryCategory selectedCategory = LibraryCategory.all;
  LibrarySourceFilter selectedSourceFilter = LibrarySourceFilter.all;
  LibrarySortOption selectedSortOption = LibrarySortOption.newest;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isLoading = true;
  String generatingAudiobookDocumentId = '';

  @override
  void initState() {
    super.initState();

    loadLibrary();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadLibrary() async {
    final localItems = await HistoryService.getHistory();
    final loadedFavorites =
        await const LibraryFavoritesService().getFavorites();
    final cloudItems = <DocumentHistory>[];
    final loadedCloudDocumentIds = <String>{};

    try {
      final cloudDocuments = await CloudApiService.getLibraryDocuments();

      final localIds = localItems
          .map((item) => item.documentId)
          .where((item) => item.trim().isNotEmpty)
          .toSet();

      for (final item in cloudDocuments) {
        if (item is! Map) continue;

        final documentId = item['document_id']?.toString().trim() ?? '';
        final fileName =
            (item['document_name'] ?? item['filename'])?.toString().trim() ??
                '';
        final createdAt =
            (item['uploaded_at'] ?? item['created_at'])?.toString().trim() ??
                DateTime.now().toIso8601String();
        final summary = item['summary']?.toString().trim() ?? '';
        final audioUrl = item['audio_url']?.toString().trim() ?? '';

        if (documentId.isEmpty || fileName.isEmpty) continue;

        loadedCloudDocumentIds.add(documentId);

        if (localIds.contains(documentId)) continue;

        cloudItems.add(
          DocumentHistory(
            documentId: documentId,
            fileName: fileName,
            summary: summary,
            audioUrl: audioUrl,
            createdAt: createdAt,
          ),
        );
      }
    } catch (error) {
      debugPrint('No se pudo cargar Biblioteca Cloud: $error');
    }

    final items = [
      ...localItems,
      ...cloudItems,
    ];

    final localAudiobooks =
        await const AudiobookLibraryService().getAudiobooks();

    final cloudAudiobooks = <AudiobookHistory>[];
    final loadedCloudAudiobookIds = <String>{};

    try {
      final rawCloudAudiobooks = await CloudApiService.getAudiobooks();

      final localAudiobookIds = localAudiobooks
          .map((item) => item.documentId)
          .where((item) => item.trim().isNotEmpty)
          .toSet();

      for (final item in rawCloudAudiobooks) {
        if (item is! Map) continue;

        final documentId = item['document_id']?.toString().trim() ?? '';
        final fileName = item['file_name']?.toString().trim() ?? '';
        final createdAt = item['created_at']?.toString().trim() ??
            DateTime.now().toIso8601String();
        final rawChapters = item['chapters'];

        final chapters = rawChapters is List
            ? rawChapters
                .whereType<Map>()
                .map((chapter) => Map<String, dynamic>.from(chapter))
                .toList()
            : <Map<String, dynamic>>[];

        if (documentId.isEmpty || fileName.isEmpty || chapters.isEmpty) {
          continue;
        }

        loadedCloudAudiobookIds.add(documentId);

        if (localAudiobookIds.contains(documentId)) {
          continue;
        }

        cloudAudiobooks.add(
          AudiobookHistory(
            documentId: documentId,
            fileName: fileName,
            chapters: chapters,
            createdAt: createdAt,
          ),
        );
      }
    } catch (error) {
      debugPrint('No se pudo cargar audiolibros cloud: $error');
    }

    final savedAudiobooks = [
      ...localAudiobooks,
      ...cloudAudiobooks,
    ];

    final chats = <_LibraryChatItem>[];
    final generated = <_LibraryGeneratedItem>[];
    final documentsById = {
      for (final document in items) document.documentId: document,
    };

    for (final document in items) {
      final messages = await ChatHistoryService.loadMessages(
        documentId: document.documentId,
      );

      final validMessages =
          messages.where((message) => message.text.trim().isNotEmpty).toList();

      if (validMessages.isNotEmpty) {
        chats.add(
          _LibraryChatItem(
            document: document,
            messageCount: validMessages.length,
            lastMessage: validMessages.last.text,
          ),
        );
      }

      if (document.hasSummary) {
        generated.add(
          _LibraryGeneratedItem.fromSummary(
            document,
            isCloud: loadedCloudDocumentIds.contains(document.documentId),
          ),
        );
      }
    }

    for (final type in const [
      'flashcards',
      'exam',
      'question_bank',
      'rubric',
      'study_guide',
    ]) {
      final results = await StudyResultService.getResultsByType(type);

      for (final result in results) {
        final item = _LibraryGeneratedItem.fromStudyResult(
          result,
          documentsById: documentsById,
          cloudDocumentIds: loadedCloudDocumentIds,
        );

        if (generated.any(
          (current) =>
              current.documentId == item.documentId &&
              current.type == item.type,
        )) {
          continue;
        }

        generated.add(item);
      }
    }

    if (!mounted) return;

    setState(() {
      documents = items;
      audiobooks = savedAudiobooks;
      cloudDocumentIds
        ..clear()
        ..addAll(loadedCloudDocumentIds);
      cloudAudiobookIds
        ..clear()
        ..addAll(loadedCloudAudiobookIds);
      favoriteDocumentIds
        ..clear()
        ..addAll(loadedFavorites);
      savedChats = chats;
      generatedItems = generated;
      isLoading = false;
    });
  }

  Future<void> setActiveDocument(DocumentHistory document) async {
    await HistoryService.saveActiveDocument(document);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${document.fileName} seleccionado como documento activo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> toggleFavorite(String documentId) async {
    await const LibraryFavoritesService().toggleFavorite(documentId);
    await loadLibrary();

    if (!mounted) return;

    final isNowFavorite = favoriteDocumentIds.contains(documentId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowFavorite ? 'Agregado a favoritos.' : 'Eliminado de favoritos.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deleteDocument(int index) async {
    if (index < 0 || index >= filteredDocuments.length) return;

    final document = filteredDocuments[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text(
          'Se eliminará "${document.fileName}" de la biblioteca. '
          'También se limpiarán audiolibros, chats, flashcards y exámenes asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await HistoryService.deleteDocument(
      documents.indexWhere(
        (item) => item.documentId == document.documentId,
      ),
    );

    await const AudiobookLibraryService().deleteAudiobook(document.documentId);
    await ChatHistoryService.clearChat(documentId: document.documentId);
    await const LibraryFavoritesService().removeFavorite(document.documentId);
    await StudyResultService.deleteResult(
      documentId: document.documentId,
      type: 'flashcards',
    );
    await StudyResultService.deleteResult(
      documentId: document.documentId,
      type: 'exam',
    );

    try {
      await CloudApiService.deleteDocument(
        documentId: document.documentId,
      );
    } catch (cloudError) {
      debugPrint('No se pudo eliminar documento cloud: $cloudError');
    }

    try {
      await CloudApiService.deleteAudiobook(
        documentId: document.documentId,
      );
    } catch (cloudError) {
      debugPrint('No se pudo eliminar audiolibro cloud: $cloudError');
    }

    try {
      await CloudApiService.deleteStudyResult(
        documentId: document.documentId,
        type: 'flashcards',
      );
      await CloudApiService.deleteStudyResult(
        documentId: document.documentId,
        type: 'exam',
      );
    } catch (cloudError) {
      debugPrint('No se pudieron eliminar resultados cloud: $cloudError');
    }

    await loadLibrary();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documento y datos asociados eliminados.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openPdf(DocumentHistory document) async {
    try {
      final signedUrl = await CloudApiService.getDocumentDownloadUrl(
        documentId: document.documentId,
      );

      final uri = Uri.parse(signedUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw StateError('No se pudo abrir el PDF.');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el PDF: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openChat(DocumentHistory document) async {
    try {
      String cloudChatId = '';

      if (isCloudDocument(document)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando documento cloud...'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await CloudApiService.rehydrateDocument(
          documentId: document.documentId,
        );

        final chats = await CloudApiService.getChats(
          documentId: document.documentId,
        );

        if (chats.isNotEmpty && chats.first is Map) {
          cloudChatId = chats.first['id']?.toString() ?? '';
        }
      }

      if (!mounted) return;

      final queryParameters = <String, String>{
        'fileName': document.fileName,
      };

      if (cloudChatId.trim().isNotEmpty) {
        queryParameters['cloudChatId'] = cloudChatId.trim();
      }

      context.go(
        Uri(
          path: '/chat/${document.documentId}',
          queryParameters: queryParameters,
        ).toString(),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo preparar el chat: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> prepareCloudDocument(DocumentHistory document) async {
    if (!isCloudDocument(document)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparando documento cloud...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await CloudApiService.rehydrateDocument(
      documentId: document.documentId,
    );
  }

  Future<void> openExam(DocumentHistory document) async {
    try {
      await prepareCloudDocument(document);

      if (!mounted) return;

      context.go('/exam/${document.documentId}');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo preparar el examen: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openFlashcards(DocumentHistory document) async {
    try {
      await prepareCloudDocument(document);

      if (!mounted) return;

      context.go('/flashcards/${document.documentId}');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron preparar las flashcards: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openGeneratedResource(_LibraryGeneratedItem item) async {
    switch (item.type) {
      case 'flashcards':
        context.go('/flashcards/${item.documentId}');
        return;
      case 'exam':
        context.go('/exam/${item.documentId}');
        return;
      case 'question_bank':
        context.go('/question-bank/${item.documentId}');
        return;
      case 'rubric':
        context.go('/rubric/${item.documentId}');
        return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Text(
              item.preview.isEmpty ? item.subtitle : item.preview,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> generateAudiobook(DocumentHistory document) async {
    final text = document.cleanSummary;

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este documento no tiene resumen suficiente para crear un audiolibro.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (generatingAudiobookDocumentId.isNotEmpty) return;

    setState(() {
      generatingAudiobookDocumentId = document.documentId;
    });

    try {
      await prepareCloudDocument(document);

      final data = await const AudiobookService().generateAudiobookFromText(
        text: text,
        maxChapters: 6,
      );

      final rawChapters = data['chapters'];
      final chapters = rawChapters is List ? rawChapters : [];

      if (chapters.isEmpty) {
        throw Exception('No se generaron capítulos de audio.');
      }

      final audiobookHistory = AudiobookHistory(
        documentId: document.documentId,
        fileName: document.fileName,
        chapters: chapters
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        createdAt: DateTime.now().toIso8601String(),
      );

      await const AudiobookLibraryService().saveAudiobook(
        audiobookHistory,
      );

      try {
        await CloudApiService.saveAudiobook(
          documentId: audiobookHistory.documentId,
          fileName: audiobookHistory.fileName,
          chapters: audiobookHistory.chapters,
        );
      } catch (cloudError) {
        debugPrint('No se pudo guardar audiolibro cloud: $cloudError');
      }

      await loadLibrary();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => _AudiobookChaptersDialog(
          documentTitle: document.fileName,
          chapters: chapters,
          onPlayChapter: (chapter) async {
            final audioUrl = chapter['audio_url']?.toString() ?? '';

            if (audioUrl.trim().isEmpty) return;

            final fullAudioUrl = ApiService.buildAudioUrl(audioUrl);

            try {
              debugPrint('[AUDIOBOOK_PLAY] url=$fullAudioUrl');

              await ref.read(audioProvider.notifier).play(
                    audioUrl: fullAudioUrl,
                    title:
                        '${chapter['title']?.toString() ?? 'Capítulo'} · ${document.fileName}',
                  );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reproduciendo capítulo del audiolibro...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (error) {
              debugPrint('[AUDIOBOOK_PLAY_ERROR] $error');

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No se pudo reproducir el capítulo: $error',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.danger,
                ),
              );
            }
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear el audiolibro: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingAudiobookDocumentId = '';
        });
      }
    }
  }

  Future<void> deleteSavedAudiobook(String documentId) async {
    await const AudiobookLibraryService().deleteAudiobook(documentId);

    try {
      await CloudApiService.deleteAudiobook(
        documentId: documentId,
      );
    } catch (cloudError) {
      debugPrint('No se pudo eliminar audiolibro cloud: $cloudError');
    }

    await loadLibrary();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audiolibro eliminado de la biblioteca.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool shouldShowCategory(LibraryCategory category) {
    return selectedCategory == LibraryCategory.all ||
        selectedCategory == category;
  }

  int categoryCount(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.all => filteredDocuments.length +
          filteredAudiobooks.length +
          filteredChats.length +
          filteredGeneratedItems.length,
      LibraryCategory.documents => filteredDocuments.length,
      LibraryCategory.generated => filteredGeneratedItems.length,
      LibraryCategory.audiobooks => filteredAudiobooks.length,
      LibraryCategory.chats => filteredChats.length,
      LibraryCategory.favorites => filteredDocuments
          .where((item) => favoriteDocumentIds.contains(item.documentId))
          .length,
    };
  }

  String categoryLabel(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.all => 'Todo',
      LibraryCategory.documents => 'Documentos',
      LibraryCategory.generated => 'Generados',
      LibraryCategory.audiobooks => 'AudioBooks',
      LibraryCategory.chats => 'Chats',
      LibraryCategory.favorites => 'Favoritos',
    };
  }

  IconData categoryIcon(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.all => Icons.dashboard_customize_rounded,
      LibraryCategory.documents => Icons.picture_as_pdf_rounded,
      LibraryCategory.generated => Icons.auto_awesome_rounded,
      LibraryCategory.audiobooks => Icons.headphones_rounded,
      LibraryCategory.chats => Icons.chat_bubble_rounded,
      LibraryCategory.favorites => Icons.star_rounded,
    };
  }

  bool isCloudDocument(DocumentHistory item) {
    return cloudDocumentIds.contains(item.documentId);
  }

  bool isCloudAudiobook(AudiobookHistory item) {
    return cloudAudiobookIds.contains(item.documentId);
  }

  bool isCloudDocumentId(String documentId) {
    return cloudDocumentIds.contains(documentId) ||
        cloudAudiobookIds.contains(documentId);
  }

  bool matchesSource({
    required bool isCloud,
  }) {
    return switch (selectedSourceFilter) {
      LibrarySourceFilter.all => true,
      LibrarySourceFilter.local => !isCloud,
      LibrarySourceFilter.cloud => isCloud,
    };
  }

  String sourceFilterLabel(LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => 'Todos',
      LibrarySourceFilter.local => 'Local',
      LibrarySourceFilter.cloud => 'Cloud',
    };
  }

  IconData sourceFilterIcon(LibrarySourceFilter filter) {
    return switch (filter) {
      LibrarySourceFilter.all => Icons.layers_rounded,
      LibrarySourceFilter.local => Icons.computer_rounded,
      LibrarySourceFilter.cloud => Icons.cloud_done_rounded,
    };
  }

  int sourceFilterCount(LibrarySourceFilter filter) {
    bool accept(bool isCloud) {
      return switch (filter) {
        LibrarySourceFilter.all => true,
        LibrarySourceFilter.local => !isCloud,
        LibrarySourceFilter.cloud => isCloud,
      };
    }

    int countAll() {
      return documents.where((item) => accept(isCloudDocument(item))).length +
          audiobooks.where((item) => accept(isCloudAudiobook(item))).length +
          savedChats
              .where(
                (item) => accept(
                  isCloudDocumentId(item.document.documentId),
                ),
              )
              .length +
          generatedItems
              .where(
                (item) => accept(item.isCloud),
              )
              .length;
    }

    return switch (selectedCategory) {
      LibraryCategory.all => countAll(),
      LibraryCategory.documents =>
        documents.where((item) => accept(isCloudDocument(item))).length,
      LibraryCategory.generated =>
        generatedItems.where((item) => accept(item.isCloud)).length,
      LibraryCategory.audiobooks =>
        audiobooks.where((item) => accept(isCloudAudiobook(item))).length,
      LibraryCategory.chats => savedChats
          .where(
            (item) => accept(
              isCloudDocumentId(item.document.documentId),
            ),
          )
          .length,
      LibraryCategory.favorites => documents
          .where(
            (item) =>
                favoriteDocumentIds.contains(item.documentId) &&
                accept(isCloudDocument(item)),
          )
          .length,
    };
  }

  Widget buildSourceFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LibrarySourceFilter.values.map((filter) {
          final isSelected = selectedSourceFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                sourceFilterIcon(filter),
                size: 17,
                color: isSelected ? Colors.white : AppTheme.accent,
              ),
              label: Text(
                '${sourceFilterLabel(filter)} (${sourceFilterCount(filter)})',
              ),
              onSelected: (_) {
                setState(() {
                  selectedSourceFilter = filter;
                });
              },
              selectedColor: AppTheme.secondary,
              backgroundColor: AppTheme.card,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.secondary
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool matchesSearch(String value) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return true;

    return value.toLowerCase().contains(query);
  }

  String sortLabel(LibrarySortOption option) {
    return switch (option) {
      LibrarySortOption.newest => 'Más reciente',
      LibrarySortOption.oldest => 'Más antiguo',
      LibrarySortOption.nameAsc => 'Nombre A-Z',
      LibrarySortOption.nameDesc => 'Nombre Z-A',
    };
  }

  DateTime parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<T> sortItems<T>({
    required List<T> items,
    required String Function(T item) name,
    required String Function(T item) date,
  }) {
    final sorted = List<T>.from(items);

    int compareNames(T a, T b) {
      final left = name(a).trim().toLowerCase();
      final right = name(b).trim().toLowerCase();

      return left.compareTo(right);
    }

    int compareDates(T a, T b) {
      final left = parseDate(date(a));
      final right = parseDate(date(b));

      return left.compareTo(right);
    }

    sorted.sort((a, b) {
      switch (selectedSortOption) {
        case LibrarySortOption.newest:
          return compareDates(b, a);
        case LibrarySortOption.oldest:
          return compareDates(a, b);
        case LibrarySortOption.nameAsc:
          return compareNames(a, b);
        case LibrarySortOption.nameDesc:
          return compareNames(b, a);
      }
    });

    return sorted;
  }

  Widget buildSortDropdown() {
    return PopupMenuButton<LibrarySortOption>(
      color: AppTheme.surface,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onSelected: (value) {
        setState(() {
          selectedSortOption = value;
        });
      },
      itemBuilder: (context) {
        return LibrarySortOption.values.map((option) {
          final isSelected = selectedSortOption == option;

          return PopupMenuItem<LibrarySortOption>(
            value: option,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.sort_rounded,
                  color: isSelected ? AppTheme.success : AppTheme.accent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  sortLabel(option),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sort_rounded,
              color: AppTheme.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              sortLabel(selectedSortOption),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchAndSortRow() {
    return Row(
      children: [
        Expanded(
          child: buildSearchBox(),
        ),
        const SizedBox(width: 12),
        buildSortDropdown(),
      ],
    );
  }

  List<DocumentHistory> get filteredDocuments {
    final items = documents.where((item) {
      if (selectedCategory == LibraryCategory.favorites &&
          !favoriteDocumentIds.contains(item.documentId)) {
        return false;
      }

      return matchesSource(isCloud: isCloudDocument(item)) &&
          (matchesSearch(item.fileName) || matchesSearch(item.cleanSummary));
    }).toList();

    return sortItems<DocumentHistory>(
      items: items,
      name: (item) => item.fileName,
      date: (item) => item.createdAt,
    );
  }

  List<AudiobookHistory> get filteredAudiobooks {
    final items = audiobooks
        .where(
          (item) =>
              matchesSource(isCloud: isCloudAudiobook(item)) &&
              matchesSearch(item.fileName),
        )
        .toList();

    return sortItems<AudiobookHistory>(
      items: items,
      name: (item) => item.fileName,
      date: (item) => item.createdAt,
    );
  }

  List<_LibraryChatItem> get filteredChats {
    final items = savedChats
        .where(
          (item) =>
              matchesSource(
                isCloud: isCloudDocumentId(item.document.documentId),
              ) &&
              (matchesSearch(item.document.fileName) ||
                  matchesSearch(item.lastMessage)),
        )
        .toList();

    return sortItems<_LibraryChatItem>(
      items: items,
      name: (item) => item.document.fileName,
      date: (item) => item.document.createdAt,
    );
  }

  List<_LibraryGeneratedItem> get filteredGeneratedItems {
    final items = generatedItems
        .where(
          (item) =>
              matchesSource(isCloud: item.isCloud) &&
              (matchesSearch(item.title) ||
                  matchesSearch(item.subtitle) ||
                  matchesSearch(item.preview)),
        )
        .toList();

    return sortItems<_LibraryGeneratedItem>(
      items: items,
      name: (item) => item.title,
      date: (item) => item.createdAt,
    );
  }

  Widget buildSearchBox() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar en la biblioteca...',
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.accent,
        ),
        suffixIcon: searchQuery.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    searchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
        filled: true,
        fillColor: AppTheme.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }

  Widget buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LibraryCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          final count = categoryCount(category);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                categoryIcon(category),
                size: 17,
                color: isSelected ? Colors.white : AppTheme.accent,
              ),
              label: Text(
                '${categoryLabel(category)} ($count)',
              ),
              onSelected: (_) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.card,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildEmptyState() {
    return SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.mainGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu biblioteca está vacía',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sube tu primer PDF para comenzar a crear resúmenes, audiolibros, flashcards y exámenes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Subir PDF'),
          ),
        ],
      ),
    );
  }

  Widget buildLibraryContent() {
    if (isLoading) {
      return const StudyBookLoadingState(
        message: 'Booky está organizando tu biblioteca...',
      );
    }

    if (documents.isEmpty) {
      return buildEmptyState();
    }

    return Column(
      children: [
        _LibrarySummary(
          totalDocuments: documents.length,
          audioCount: audiobooks.length,
          generatedCount: generatedItems.length,
        ),
        const SizedBox(height: 18),
        buildCategoryTabs(),
        const SizedBox(height: 12),
        buildSourceFilterTabs(),
        const SizedBox(height: 14),
        buildSearchAndSortRow(),
        if (sourceFilterCount(selectedSourceFilter) == 0) ...[
          const SizedBox(height: 22),
          SectionCard(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  color: AppTheme.textMuted,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay elementos para mostrar',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cambia el filtro, la categoría o el texto de búsqueda.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (shouldShowCategory(LibraryCategory.generated) &&
            filteredGeneratedItems.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SavedGeneratedSection(
            items: filteredGeneratedItems,
            onOpen: openGeneratedResource,
          ),
        ],
        if (shouldShowCategory(LibraryCategory.chats) &&
            filteredChats.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SavedChatsSection(
            chats: filteredChats,
            onOpenChat: openChat,
          ),
        ],
        if (shouldShowCategory(LibraryCategory.audiobooks) &&
            filteredAudiobooks.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SavedAudiobooksSection(
            audiobooks: filteredAudiobooks,
            cloudAudiobookIds: cloudAudiobookIds,
            onDeleteAudiobook: deleteSavedAudiobook,
            onPlayChapter: (audiobook, chapter) async {
              final audioUrl = chapter['audio_url']?.toString() ?? '';

              if (audioUrl.trim().isEmpty) return;

              final fullAudioUrl = ApiService.buildAudioUrl(audioUrl);

              await ref.read(audioProvider.notifier).play(
                    audioUrl: fullAudioUrl,
                    title:
                        '${chapter['title']?.toString() ?? 'Capítulo'} · ${audiobook.fileName}',
                  );
            },
          ),
        ],
        if ((shouldShowCategory(LibraryCategory.documents) ||
                selectedCategory == LibraryCategory.favorites ||
                selectedCategory == LibraryCategory.all) &&
            filteredDocuments.isNotEmpty &&
            sourceFilterCount(selectedSourceFilter) > 0) ...[
          const SizedBox(height: 18),
          ...filteredDocuments.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final document = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DocumentLibraryCard(
                  document: document,
                  isGeneratingAudiobook:
                      generatingAudiobookDocumentId == document.documentId,
                  isFavorite: favoriteDocumentIds.contains(document.documentId),
                  onToggleFavorite: () => toggleFavorite(document.documentId),
                  onSetActive: () => setActiveDocument(document),
                  onOpenPdf: () => openPdf(document),
                  onChat: () {
                    openChat(document);
                  },
                  onAudio: () {
                    generateAudiobook(document);
                  },
                  onFlashcards: () {
                    openFlashcards(document);
                  },
                  onExam: () {
                    openExam(document);
                  },
                  onDelete: () => deleteDocument(index),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget buildBody() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: AppTheme.mainGradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.library_books_rounded,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'Biblioteca Inteligente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Organiza tus documentos, chats, audiolibros, flashcards y exámenes en un solo lugar.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        buildLibraryContent(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudyBookAppShell(
      currentRoute: '/library',
      maxContentWidth: 1080,
      child: Column(
        children: [
          Expanded(child: buildBody()),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  final int totalDocuments;
  final int audioCount;
  final int generatedCount;

  const _LibrarySummary({
    required this.totalDocuments,
    required this.audioCount,
    required this.generatedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LibraryMetric(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Documentos',
            value: totalDocuments.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LibraryMetric(
            icon: Icons.auto_awesome_rounded,
            label: 'Generados',
            value: generatedCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LibraryMetric(
            icon: Icons.headphones_rounded,
            label: 'Audios',
            value: audioCount.toString(),
          ),
        ),
      ],
    );
  }
}

class _LibraryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LibraryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryChatItem {
  final DocumentHistory document;
  final int messageCount;
  final String lastMessage;

  const _LibraryChatItem({
    required this.document,
    required this.messageCount,
    required this.lastMessage,
  });
}

class _LibraryGeneratedItem {
  final String documentId;
  final String sourceDocumentId;
  final String type;
  final String title;
  final String subtitle;
  final String content;
  final String createdAt;
  final bool isCloud;

  const _LibraryGeneratedItem({
    required this.documentId,
    required this.sourceDocumentId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.createdAt,
    required this.isCloud,
  });

  factory _LibraryGeneratedItem.fromSummary(
    DocumentHistory document, {
    required bool isCloud,
  }) {
    return _LibraryGeneratedItem(
      documentId: document.documentId,
      sourceDocumentId: document.documentId,
      type: 'summary',
      title: 'Resumen - ${document.fileName}',
      subtitle: document.fileName,
      content: document.cleanSummary,
      createdAt: document.createdAt,
      isCloud: isCloud,
    );
  }

  factory _LibraryGeneratedItem.fromStudyResult(
    StudyResult result, {
    required Map<String, DocumentHistory> documentsById,
    required Set<String> cloudDocumentIds,
  }) {
    final decoded = _decode(result.content);
    final metadata = _firstMetadataMap(decoded);
    final sourceDocumentId =
        _firstText(metadata, const ['source_document_id', 'sourceDocumentId']);
    final document = documentsById[sourceDocumentId] ??
        documentsById[result.documentId] ??
        documentsById[result.documentId
            .replaceAll(RegExp(r'_question_bank$'), '')
            .replaceAll(RegExp(r'_unit_exam$'), '')
            .replaceAll(RegExp(r'_rubric$'), '')
            .replaceAll(RegExp(r'_study_guide$'), '')];
    final topic = _firstText(
      metadata,
      const [
        'unit_topic',
        'program_topic',
        'exam_topic',
        'topic',
        'course_name',
      ],
    );
    final fallbackName = document?.fileName ?? topic;

    return _LibraryGeneratedItem(
      documentId: result.documentId,
      sourceDocumentId: sourceDocumentId.isEmpty
          ? document?.documentId ?? result.documentId
          : sourceDocumentId,
      type: result.type,
      title: _titleFor(result.type, metadata, fallbackName),
      subtitle: _subtitleFor(result.type, metadata, fallbackName),
      content: result.content,
      createdAt: result.createdAt,
      isCloud: sourceDocumentId.isNotEmpty
          ? cloudDocumentIds.contains(sourceDocumentId)
          : cloudDocumentIds.contains(document?.documentId ?? ''),
    );
  }

  IconData get icon {
    return switch (type) {
      'summary' => Icons.summarize_rounded,
      'flashcards' => Icons.style_rounded,
      'exam' => Icons.quiz_rounded,
      'question_bank' => Icons.fact_check_rounded,
      'rubric' => Icons.assignment_turned_in_rounded,
      'study_guide' => Icons.menu_book_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  String get typeLabel {
    return switch (type) {
      'summary' => 'Resumen',
      'flashcards' => 'Flashcards',
      'exam' => 'Examen',
      'question_bank' => 'Banco',
      'rubric' => 'Rúbrica',
      'study_guide' => 'Guía',
      _ => 'Generado',
    };
  }

  String get actionLabel {
    return switch (type) {
      'summary' => 'Leer resumen',
      'flashcards' => 'Abrir flashcards',
      'exam' => 'Abrir examen',
      'question_bank' => 'Abrir banco',
      'rubric' => 'Abrir rúbrica',
      'study_guide' => 'Ver guía',
      _ => 'Abrir',
    };
  }

  String get preview {
    final cleanContent = content
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'[\{\}\[\]"]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleanContent;
  }

  static dynamic _decode(String content) {
    try {
      return jsonDecode(content);
    } catch (_) {
      return content;
    }
  }

  static Map<String, dynamic> _firstMetadataMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }

    return {};
  }

  static String _firstText(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = metadata[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  static String _titleFor(
    String type,
    Map<String, dynamic> metadata,
    String fallbackName,
  ) {
    final explicit = _firstText(
      metadata,
      const [
        'title',
        'exam_title',
        'rubric_title',
        'guide_title',
        'bank_title',
      ],
    );

    if (explicit.isNotEmpty) return explicit;

    final cleanFallback =
        fallbackName.trim().isEmpty ? 'material' : fallbackName.trim();

    return switch (type) {
      'flashcards' => 'Flashcards - $cleanFallback',
      'exam' => 'Examen - $cleanFallback',
      'question_bank' => 'Banco de preguntas - $cleanFallback',
      'rubric' => 'Rúbrica - $cleanFallback',
      'study_guide' => 'Guía de estudio - $cleanFallback',
      _ => 'Recurso generado - $cleanFallback',
    };
  }

  static String _subtitleFor(
    String type,
    Map<String, dynamic> metadata,
    String fallbackName,
  ) {
    final unit = _firstText(metadata, const ['unit_topic', 'program_topic']);
    final course = _firstText(
      metadata,
      const ['course_display_name', 'course_name', 'course_code'],
    );
    final parts = [
      if (unit.isNotEmpty) unit,
      if (course.isNotEmpty) course,
      if (unit.isEmpty && course.isEmpty && fallbackName.trim().isNotEmpty)
        fallbackName.trim(),
    ];

    if (parts.isEmpty) return 'Recurso académico generado';

    return parts.join(' · ');
  }
}

class _SavedChatsSection extends StatelessWidget {
  final List<_LibraryChatItem> chats;
  final void Function(DocumentHistory document) onOpenChat;

  const _SavedChatsSection({
    required this.chats,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                color: AppTheme.accent,
              ),
              SizedBox(width: 10),
              Text(
                'Chats guardados',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Continúa conversaciones anteriores con tus documentos.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...chats.map(
            (item) => _SavedChatTile(
              item: item,
              onOpenChat: onOpenChat,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedChatTile extends StatelessWidget {
  final _LibraryChatItem item;
  final void Function(DocumentHistory document) onOpenChat;

  const _SavedChatTile({
    required this.item,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.forum_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.document.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.messageCount} mensajes · ${item.lastMessage}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => onOpenChat(item.document),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Abrir chat'),
          ),
        ],
      ),
    );
  }
}

class _SavedGeneratedSection extends StatelessWidget {
  final List<_LibraryGeneratedItem> items;
  final void Function(_LibraryGeneratedItem item) onOpen;

  const _SavedGeneratedSection({
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accent,
              ),
              SizedBox(width: 10),
              Text(
                'Recursos generados',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Resúmenes, flashcards, exámenes, bancos, rúbricas y guías listos para reutilizar.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => _SavedGeneratedTile(
              item: item,
              onOpen: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedGeneratedTile extends StatelessWidget {
  final _LibraryGeneratedItem item;
  final void Function(_LibraryGeneratedItem item) onOpen;

  const _SavedGeneratedTile({
    required this.item,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                color: AppTheme.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.typeLabel,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (item.preview.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => onOpen(item),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(item.actionLabel),
              ),
              _LibraryPill(
                icon: item.isCloud
                    ? Icons.cloud_done_rounded
                    : Icons.computer_rounded,
                label: item.isCloud ? 'Cloud' : 'Local',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LibraryPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.textMuted,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAudiobooksSection extends StatelessWidget {
  final List<AudiobookHistory> audiobooks;
  final Set<String> cloudAudiobookIds;
  final Future<void> Function(String documentId) onDeleteAudiobook;
  final Future<void> Function(
    AudiobookHistory audiobook,
    Map<String, dynamic> chapter,
  ) onPlayChapter;

  const _SavedAudiobooksSection({
    required this.audiobooks,
    required this.cloudAudiobookIds,
    required this.onDeleteAudiobook,
    required this.onPlayChapter,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                color: AppTheme.accent,
              ),
              SizedBox(width: 10),
              Text(
                'Audiolibros guardados',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Escucha tus audiolibros generados sin volver a procesarlos.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...audiobooks.map(
            (audiobook) => _SavedAudiobookTile(
              audiobook: audiobook,
              isCloud: cloudAudiobookIds.contains(audiobook.documentId),
              onDeleteAudiobook: onDeleteAudiobook,
              onPlayChapter: onPlayChapter,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAudiobookTile extends StatelessWidget {
  final AudiobookHistory audiobook;
  final bool isCloud;
  final Future<void> Function(String documentId) onDeleteAudiobook;
  final Future<void> Function(
    AudiobookHistory audiobook,
    Map<String, dynamic> chapter,
  ) onPlayChapter;

  const _SavedAudiobookTile({
    required this.audiobook,
    required this.isCloud,
    required this.onDeleteAudiobook,
    required this.onPlayChapter,
  });

  int get totalEstimatedMinutes {
    int total = 0;

    for (final chapter in audiobook.chapters) {
      final value = chapter['estimated_minutes'];

      if (value is int) {
        total += value;
      } else {
        total += int.tryParse(value?.toString() ?? '') ?? 1;
      }
    }

    return total <= 0 ? 1 : total;
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(audiobook.createdAt);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return audiobook.createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstChapter =
        audiobook.chapters.isNotEmpty ? audiobook.chapters.first : null;

    final hasMultipleChapters = audiobook.chapters.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.audiotrack_rounded,
                color: AppTheme.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  audiobook.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar audiolibro',
                onPressed: () async {
                  await onDeleteAudiobook(audiobook.documentId);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${audiobook.chapterCount} capítulo${audiobook.chapterCount == 1 ? '' : 's'}'
            ' • $totalEstimatedMinutes min aprox. • $formattedDate',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (firstChapter != null)
                FilledButton.icon(
                  onPressed: () async {
                    await onPlayChapter(audiobook, firstChapter);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    hasMultipleChapters
                        ? 'Escuchar desde inicio'
                        : 'Escuchar audiolibro',
                  ),
                ),
              if (hasMultipleChapters)
                ...audiobook.chapters.take(6).map(
                      (chapter) => OutlinedButton.icon(
                        onPressed: () async {
                          await onPlayChapter(audiobook, chapter);
                        },
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(
                          chapter['title']?.toString() ?? 'Capítulo',
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentLibraryCard extends StatelessWidget {
  final DocumentHistory document;
  final bool isGeneratingAudiobook;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onSetActive;
  final VoidCallback onOpenPdf;
  final VoidCallback onChat;
  final VoidCallback onAudio;
  final VoidCallback onFlashcards;
  final VoidCallback onExam;
  final VoidCallback onDelete;

  const _DocumentLibraryCard({
    required this.document,
    required this.isGeneratingAudiobook,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onSetActive,
    required this.onOpenPdf,
    required this.onChat,
    required this.onAudio,
    required this.onFlashcards,
    required this.onExam,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.formattedDate,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        if (!document.hasSummary && !document.hasAudio)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Cloud',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Quitar favorito' : 'Marcar favorito',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite ? AppTheme.warning : AppTheme.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
          if (document.cleanSummary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              document.cleanSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onOpenPdf,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Abrir PDF'),
              ),
              FilledButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Chat'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingAudiobook ? null : onAudio,
                icon: isGeneratingAudiobook
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(Icons.headphones_rounded),
                label: Text(
                  isGeneratingAudiobook
                      ? 'Creando...'
                      : document.hasAudio
                          ? 'Escuchar'
                          : 'Crear audiolibro',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onFlashcards,
                icon: const Icon(Icons.style_rounded),
                label: const Text('Flashcards'),
              ),
              OutlinedButton.icon(
                onPressed: onExam,
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Examen'),
              ),
              OutlinedButton.icon(
                onPressed: onSetActive,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Usar como activo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudiobookChaptersDialog extends StatelessWidget {
  final String documentTitle;
  final List<dynamic> chapters;
  final Future<void> Function(Map<String, dynamic> chapter) onPlayChapter;

  const _AudiobookChaptersDialog({
    required this.documentTitle,
    required this.chapters,
    required this.onPlayChapter,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.mainGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.headphones_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audiolibro generado',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              documentTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona un capítulo. Luego usa el MiniPlayer para pausar, avanzar o reiniciar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final rawChapter = chapters[index];
                  final chapter = rawChapter is Map<String, dynamic>
                      ? rawChapter
                      : Map<String, dynamic>.from(rawChapter as Map);

                  final title =
                      chapter['title']?.toString() ?? 'Capítulo ${index + 1}';
                  final estimatedMinutes =
                      chapter['estimated_minutes']?.toString() ?? '1';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.headphones_rounded,
                        color: AppTheme.accent,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '$estimatedMinutes min aprox. · toca reproducir',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Reproducir capítulo',
                        onPressed: () async {
                          await onPlayChapter(chapter);

                          if (!context.mounted) return;

                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      onTap: () async {
                        await onPlayChapter(chapter);

                        if (!context.mounted) return;

                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
