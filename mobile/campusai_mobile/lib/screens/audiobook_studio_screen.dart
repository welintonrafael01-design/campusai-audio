import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/study_result.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/audiobook_progress_service.dart';
import '../services/audiobook_service.dart';
import '../services/learning_engine/learning_progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/launch_empty_state.dart';
import '../widgets/section_card.dart';

class AudioBookStudioScreen extends StatefulWidget {
  final String sourceMode;
  final String sourceType;
  final String sourceDocumentId;
  final String courseId;
  final String courseName;
  final String unitId;
  final String unitTopic;
  final String initialTitle;
  final String initialText;

  const AudioBookStudioScreen({
    super.key,
    this.sourceMode = 'solo',
    this.sourceType = 'text',
    this.sourceDocumentId = '',
    this.courseId = '',
    this.courseName = '',
    this.unitId = '',
    this.unitTopic = '',
    this.initialTitle = '',
    this.initialText = '',
  });

  @override
  State<AudioBookStudioScreen> createState() => _AudioBookStudioScreenState();
}

class _AudioBookStudioScreenState extends State<AudioBookStudioScreen> {
  final titleController = TextEditingController();
  final textController = TextEditingController();
  final audiobookService = const AudiobookService();
  final progressService = const AudiobookProgressService();
  final audioPlayerService = AudioPlayerService();
  final learningProgressService = const LearningProgressService();

  bool isGenerating = false;
  bool isLoadingSavedAudioBooks = true;
  final Set<String> generatingAudioChapterIds = {};
  final Set<String> generatingLearningPackChapterIds = {};
  final Map<String, String> chapterAudioErrors = {};
  final Map<String, String> chapterLearningPackErrors = {};
  final Map<String, String> quizAnswers = {};
  List<StudyResult> savedAudioBooks = [];
  Map<String, Map<String, dynamic>> savedProgressByAudioBookId = {};
  Map<String, dynamic> selectedAudioBook = {};
  Map<String, dynamic> selectedProgress = {};
  String selectedChapterId = '';
  bool isPlaying = false;
  int currentPositionSeconds = 0;
  double playbackSpeed = 1.0;
  String selectedVoiceProfile = 'standard';
  Timer? playbackTimer;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.initialTitle.trim().isNotEmpty
        ? widget.initialTitle.trim()
        : widget.unitTopic.trim().isNotEmpty
            ? 'Audio Libro - ${widget.unitTopic.trim()}'
            : '';
    textController.text = widget.initialText;
    loadSavedAudioBooks();
  }

  @override
  void dispose() {
    playbackTimer?.cancel();
    audioPlayerService.dispose();
    titleController.dispose();
    textController.dispose();
    super.dispose();
  }

  Future<void> loadSavedAudioBooks() async {
    if (mounted) setState(() => isLoadingSavedAudioBooks = true);

    try {
      final results = await audiobookService.getAudioBooks();
      final progressById = <String, Map<String, dynamic>>{};

      for (final result in results) {
        final audiobook = audiobookService.decodeAudioBook(result);
        final audiobookId = cleanText(audiobook['audiobook_id']).isNotEmpty
            ? cleanText(audiobook['audiobook_id'])
            : result.documentId;
        progressById[audiobookId] = await progressService.getProgress(
          audiobookId,
        );
      }

      if (!mounted) return;
      setState(() {
        savedAudioBooks = audiobookService.sortedAudioBooksByProgress(
          results,
          progressById,
        );
        savedProgressByAudioBookId = progressById;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        savedAudioBooks = [];
        savedProgressByAudioBookId = {};
      });
    } finally {
      if (mounted) setState(() => isLoadingSavedAudioBooks = false);
    }
  }

  Future<void> generateAudioBook() async {
    if (isGenerating) return;

    final text = textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Escribe contenido académico para generar el Audio Libro.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    stopPlayback(savePosition: false);
    setState(() => isGenerating = true);

    try {
      final generated = await audiobookService.generateFromText(
        title: titleController.text.trim(),
        text: text,
        sourceMode: widget.sourceMode,
        sourceType: widget.sourceType,
        sourceDocumentId: widget.sourceDocumentId,
        courseId: widget.courseId,
        courseName: widget.courseName,
        unitId: widget.unitId,
        unitTopic: widget.unitTopic,
      );
      final documentId = await audiobookService.saveAudioBook(generated);
      final normalized = {
        ...generated,
        'audiobook_id': documentId,
      };
      final savedProgress = await progressService.getProgress(documentId);

      if (!mounted) return;

      setState(() {
        selectedAudioBook = normalized;
        selectedProgress = savedProgress;
        selectedChapterId = initialChapterId(
          audiobook: normalized,
          progress: savedProgress,
          continueFromProgress: true,
        );
        currentPositionSeconds = intFrom(
          savedProgress['current_position_seconds'],
        );
      });

      await loadSavedAudioBooks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio Libro generado y guardado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el Audio Libro: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  Future<void> openAudioBook(
    StudyResult result, {
    bool continueFromProgress = false,
  }) async {
    stopPlayback(savePosition: true);

    final latestResult = await audiobookService.getAudioBookById(
      result.documentId,
    );
    final audiobook = audiobookService.decodeAudioBook(latestResult ?? result);
    final audiobookId = cleanText(audiobook['audiobook_id']).isNotEmpty
        ? cleanText(audiobook['audiobook_id'])
        : result.documentId;
    final loadedProgress = await progressService.getProgress(audiobookId);
    final chapterId = initialChapterId(
      audiobook: audiobook,
      progress: loadedProgress,
      continueFromProgress: continueFromProgress,
    );
    final progressChapterId = cleanText(
      loadedProgress['current_chapter_id'],
    );
    final position = continueFromProgress && chapterId == progressChapterId
        ? intFrom(loadedProgress['current_position_seconds'])
        : 0;

    if (!mounted) return;
    setState(() {
      selectedAudioBook = {
        ...audiobook,
        'audiobook_id': audiobookId,
      };
      selectedProgress = loadedProgress;
      selectedChapterId = chapterId;
      currentPositionSeconds = position;
    });
  }

  Future<void> generateAudioForChapter(Map<String, dynamic> chapter) async {
    final chapterId = cleanText(chapter['chapter_id']);
    if (chapterId.isEmpty || generatingAudioChapterIds.contains(chapterId)) {
      return;
    }

    setState(() => generatingAudioChapterIds.add(chapterId));

    try {
      final updatedAudioBook = await audiobookService.generateChapterAudio(
        audiobook: selectedAudioBook,
        chapterId: chapterId,
        voiceProfile: backendVoiceProfile(selectedVoiceProfile),
      );
      final updatedChapter = audiobookService
          .chapterListFrom(updatedAudioBook['chapters'])
          .firstWhere(
            (item) => cleanText(item['chapter_id']) == chapterId,
            orElse: () => <String, dynamic>{},
          );
      final audioUrl = cleanText(updatedChapter['audio_url']);
      final failed = updatedAudioBook['_last_audio_generation_failed'] == true;

      if (!mounted) return;
      setState(() {
        selectedAudioBook = Map<String, dynamic>.from(updatedAudioBook)
          ..remove('_last_audio_generation_failed')
          ..remove('_last_audio_generation_chapter_id');
        if (failed || audioUrl.isEmpty) {
          chapterAudioErrors[chapterId] = 'tts_failed';
        } else {
          chapterAudioErrors.remove(chapterId);
        }
      });

      await loadSavedAudioBooks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !failed && audioUrl.isNotEmpty
                ? 'Audio generado para este capítulo.'
                : 'No se pudo generar audio real. Puedes seguir usando reproducción simulada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => chapterAudioErrors[chapterId] = 'tts_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo generar audio real. Puedes seguir usando reproducción simulada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => generatingAudioChapterIds.remove(chapterId));
      }
    }
  }

  Future<void> generateLearningPackForChapter(
    Map<String, dynamic> chapter,
  ) async {
    final chapterId = cleanText(chapter['chapter_id']);
    if (chapterId.isEmpty ||
        generatingLearningPackChapterIds.contains(chapterId)) {
      return;
    }

    setState(() => generatingLearningPackChapterIds.add(chapterId));

    try {
      final updatedAudioBook =
          await audiobookService.generateLearningPackForChapter(
        audiobook: selectedAudioBook,
        chapterId: chapterId,
      );
      final failed =
          updatedAudioBook['_last_learning_pack_generation_failed'] == true;
      final updatedChapter = audiobookService
          .chapterListFrom(updatedAudioBook['chapters'])
          .firstWhere(
            (item) => cleanText(item['chapter_id']) == chapterId,
            orElse: () => <String, dynamic>{},
          );
      final hasLearningPack = audiobookService.hasLearningPack(updatedChapter);

      if (!mounted) return;
      setState(() {
        selectedAudioBook = Map<String, dynamic>.from(updatedAudioBook)
          ..remove('_last_learning_pack_generation_failed')
          ..remove('_last_learning_pack_generation_chapter_id');
        if (failed || !hasLearningPack) {
          chapterLearningPackErrors[chapterId] = 'learning_pack_failed';
        } else {
          chapterLearningPackErrors.remove(chapterId);
        }
      });

      await loadSavedAudioBooks();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !failed && hasLearningPack
                ? 'Actividades listas para este capítulo.'
                : 'No se pudieron generar actividades. Puedes seguir escuchando el capítulo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
          () => chapterLearningPackErrors[chapterId] = 'learning_pack_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron generar actividades. Puedes seguir escuchando el capítulo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => generatingLearningPackChapterIds.remove(chapterId));
      }
    }
  }

  void playChapter(Map<String, dynamic> chapter) {
    unawaited(_playChapter(chapter));
  }

  void resumeSelectedChapter() {
    final chapter = selectedChapter;
    if (chapter == null) return;
    playChapter(chapter);
  }

  Future<void> _playChapter(Map<String, dynamic> chapter) async {
    final chapterId = cleanText(chapter['chapter_id']);
    if (chapterId.isEmpty) return;

    if (selectedChapterId != chapterId) {
      await saveCurrentProgress();
      setState(() {
        selectedChapterId = chapterId;
        currentPositionSeconds = 0;
      });
    }

    final audioUrl = cleanText(chapter['audio_url']);
    if (audioUrl.isNotEmpty) {
      await startRealAudioPlayback(chapter);
      return;
    }

    startSimulatedPlayback();
  }

  void startSimulatedPlayback() {
    if (selectedChapterId.isEmpty) return;

    playbackTimer?.cancel();
    unawaited(audioPlayerService.pause());
    setState(() => isPlaying = true);

    playbackTimer = Timer.periodic(simulatedTickDuration, (_) {
      final chapter = selectedChapter;
      if (chapter == null) return;

      final duration = audiobookService.chapterDurationSeconds(chapter);
      final nextPosition = currentPositionSeconds + 1;

      if (nextPosition >= duration) {
        setState(() {
          currentPositionSeconds = duration;
          isPlaying = false;
        });
        playbackTimer?.cancel();
        completeSelectedChapter(showMessage: true);
        return;
      }

      setState(() => currentPositionSeconds = nextPosition);
      if (nextPosition % 10 == 0) saveCurrentProgress();
    });
  }

  Future<void> startRealAudioPlayback(Map<String, dynamic> chapter) async {
    final audioUrl = ApiService.buildAudioUrl(cleanText(chapter['audio_url']));
    if (audioUrl.isEmpty) {
      startSimulatedPlayback();
      return;
    }

    playbackTimer?.cancel();

    try {
      await audioPlayerService.play(audioUrl);
      await audioPlayerService.setSpeed(playbackSpeed);
      if (currentPositionSeconds > 0) {
        await audioPlayerService.seek(
          Duration(seconds: currentPositionSeconds),
        );
      }

      if (!mounted) return;
      setState(() => isPlaying = true);

      playbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final duration = audioPlayerService.totalDuration?.inSeconds ??
            audiobookService.chapterDurationSeconds(chapter);
        final position = audioPlayerService.currentPosition.inSeconds;

        if (mounted) {
          setState(() => currentPositionSeconds = position);
        }

        if (duration > 0 && position >= duration) {
          playbackTimer?.cancel();
          unawaited(completeSelectedChapter(showMessage: true));
          return;
        }

        if (position > 0 && position % 10 == 0) {
          unawaited(saveCurrentProgress());
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo reproducir el audio real. Se usará reproducción simulada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      startSimulatedPlayback();
    }
  }

  Future<void> pausePlayback() async {
    playbackTimer?.cancel();
    if (selectedChapterHasAudio) {
      await audioPlayerService.pause();
      currentPositionSeconds = audioPlayerService.currentPosition.inSeconds;
    }
    if (mounted) setState(() => isPlaying = false);
    await saveCurrentProgress();
  }

  Future<void> updatePlaybackSpeed(double speed) async {
    if (speed <= 0) return;

    playbackTimer?.cancel();
    final wasPlaying = isPlaying;
    setState(() {
      playbackSpeed = speed;
      isPlaying = false;
    });

    await audioPlayerService.setSpeed(speed);

    if (wasPlaying) {
      resumeSelectedChapter();
    }
  }

  void stopPlayback({required bool savePosition}) {
    playbackTimer?.cancel();
    unawaited(audioPlayerService.pause());
    if (isPlaying && savePosition) unawaited(saveCurrentProgress());
    isPlaying = false;
  }

  Future<void> restartChapter() async {
    playbackTimer?.cancel();
    await audioPlayerService.pause();
    if (selectedChapterHasAudio) {
      await audioPlayerService.seek(Duration.zero);
    }
    setState(() {
      isPlaying = false;
      currentPositionSeconds = 0;
    });
    await saveCurrentProgress();
  }

  Future<void> completeSelectedChapter({bool showMessage = false}) async {
    final audiobookId = cleanText(selectedAudioBook['audiobook_id']);
    if (audiobookId.isEmpty || selectedChapterId.isEmpty) return;

    playbackTimer?.cancel();
    await audioPlayerService.pause();
    final updatedProgress = await progressService.markChapterCompleted(
      audiobookId: audiobookId,
      chapterId: selectedChapterId,
      chapters: chapters,
      currentPositionSeconds: currentPositionSeconds,
    );
    final nextId = cleanText(updatedProgress['current_chapter_id']);
    final shouldMoveToNext = nextId.isNotEmpty && nextId != selectedChapterId;

    if (!mounted) return;
    setState(() {
      selectedProgress = updatedProgress;
      selectedChapterId = nextId.isNotEmpty ? nextId : selectedChapterId;
      currentPositionSeconds = shouldMoveToNext
          ? 0
          : intFrom(updatedProgress['current_position_seconds']);
      isPlaying = false;
    });

    await loadSavedAudioBooks();

    if (!mounted || !showMessage) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Capítulo completado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> goToNextChapter() async {
    final nextId = progressService.nextChapterId(chapters, selectedChapterId);
    if (nextId.isEmpty) return;

    await saveCurrentProgress();
    playbackTimer?.cancel();
    await audioPlayerService.pause();
    setState(() {
      selectedChapterId = nextId;
      currentPositionSeconds = 0;
      isPlaying = false;
    });
    await saveCurrentProgress();
  }

  Future<void> saveCurrentProgress() async {
    final audiobookId = cleanText(selectedAudioBook['audiobook_id']);
    if (audiobookId.isEmpty || selectedChapterId.isEmpty) return;

    await progressService.saveProgress(
      audiobookId: audiobookId,
      currentChapterId: selectedChapterId,
      currentPositionSeconds: currentPositionSeconds,
      completedChapters: stringListFrom(selectedProgress['completed_chapters']),
      totalChapters: chapters.length,
    );
    final updatedProgress = await progressService.getProgress(audiobookId);
    if (!mounted) return;

    setState(() {
      selectedProgress = updatedProgress;
      savedProgressByAudioBookId = {
        ...savedProgressByAudioBookId,
        audiobookId: updatedProgress,
      };
    });
  }

  void openVoiceTutorForChapter(
    Map<String, dynamic> chapter, {
    bool startWithVoice = false,
  }) {
    final audiobookId = cleanText(selectedAudioBook['audiobook_id']);
    final chapterId = cleanText(chapter['chapter_id']);
    final chapterTitle = audiobookService.chapterTitle(chapter);

    context.goNamed(
      'voiceTutor',
      extra: {
        'audiobookId': audiobookId,
        'chapterId': chapterId,
        'title': 'Tutor IA',
        'suggested_prompt': chapterTitle.isEmpty
            ? 'Ayúdame a estudiar este capítulo.'
            : 'Ayúdame a estudiar $chapterTitle.',
        'start_with_voice': startWithVoice,
      },
    );
  }

  void showTranscript(Map<String, dynamic> chapter) {
    final transcript = firstCleanTextFrom([
      chapter['transcript'],
      chapter['script'],
      chapter['summary'],
    ]);
    final summary = cleanText(chapter['summary']);
    final concepts = stringListFrom(chapter['key_concepts']);
    final questions = stringListFrom(chapter['reflection_questions']);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cleanText(chapter['title']).isNotEmpty
                        ? cleanText(chapter['title'])
                        : 'Transcripción',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      summary,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    transcript.isEmpty
                        ? 'No hay transcripción disponible.'
                        : transcript,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  _BulletBlock(
                    title: 'Conceptos clave',
                    items: concepts,
                  ),
                  _BulletBlock(
                    title: 'Preguntas de reflexión',
                    items: questions,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showLearningPack(Map<String, dynamic> chapter) {
    final learningPack = audiobookService.learningPackFromChapter(chapter);
    if (learningPack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero genera las actividades de este capítulo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final flashcards = audiobookService.learningPackFlashcards(chapter);
    final miniQuiz = audiobookService.learningPackQuiz(chapter);
    final competencies = audiobookService.learningPackCompetencies(chapter);
    final reflectionQuestions = stringListFrom(
      learningPack['reflection_questions'],
    );
    final masteryCheck = learningPack['mastery_check'] is Map
        ? Map<String, dynamic>.from(learningPack['mastery_check'] as Map)
        : <String, dynamic>{};
    final revealedFlashcards = <int>{};

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanText(learningPack['chapter_title']).isNotEmpty
                            ? cleanText(learningPack['chapter_title'])
                            : audiobookService.chapterTitle(chapter),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              '${intFrom(learningPack['estimated_study_minutes'])} min de estudio',
                            ),
                          ),
                          Chip(
                            label: Text(
                              cleanText(learningPack['difficulty']).isEmpty
                                  ? 'Dificultad: Media'
                                  : 'Dificultad: ${cleanText(learningPack['difficulty'])}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              cleanText(masteryCheck['status']).isEmpty
                                  ? 'Pendiente'
                                  : cleanText(masteryCheck['status']),
                            ),
                          ),
                        ],
                      ),
                      _LearningSection(
                        title: 'Resumen',
                        child: Text(
                          cleanText(learningPack['summary']).isEmpty
                              ? 'No hay resumen disponible.'
                              : cleanText(learningPack['summary']),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                      _LearningSection(
                        title: 'Flashcards',
                        child: flashcards.isEmpty
                            ? const Text(
                                'Genera actividades para practicar con flashcards.',
                                style: TextStyle(color: AppTheme.textMuted),
                              )
                            : Column(
                                children: flashcards.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final card = entry.value;
                                    final revealed =
                                        revealedFlashcards.contains(index);

                                    return _FlashcardTile(
                                      front: cleanText(card['front']),
                                      back: cleanText(card['back']),
                                      hint: cleanText(card['hint']),
                                      revealed: revealed,
                                      onReveal: () {
                                        setSheetState(
                                          () => revealedFlashcards.add(index),
                                        );
                                      },
                                    );
                                  },
                                ).toList(),
                              ),
                      ),
                      _LearningSection(
                        title: 'Mini Quiz',
                        child: miniQuiz.isEmpty
                            ? const Text(
                                'Genera actividades para activar el mini quiz.',
                                style: TextStyle(color: AppTheme.textMuted),
                              )
                            : Column(
                                children: miniQuiz.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final question = entry.value;
                                    final answerKey =
                                        '${cleanText(chapter['chapter_id'])}_$index';
                                    final selectedAnswer =
                                        quizAnswers[answerKey] ?? '';

                                    return _QuizQuestionTile(
                                      question: question,
                                      selectedAnswer: selectedAnswer,
                                      cleanText: cleanText,
                                      onSelect: (answer) async {
                                        setState(
                                          () => quizAnswers[answerKey] = answer,
                                        );
                                        setSheetState(() {});
                                        await saveLearningQuizAnswer(
                                          chapter: chapter,
                                          miniQuiz: miniQuiz,
                                          questionIndex: index,
                                          selectedAnswer: answer,
                                        );
                                      },
                                    );
                                  },
                                ).toList(),
                              ),
                      ),
                      _LearningSection(
                        title: 'Reflexión',
                        child: _BulletBlock(
                          title: 'Preguntas de reflexión',
                          items: reflectionQuestions,
                        ),
                      ),
                      _LearningSection(
                        title: 'Competencias',
                        child: _BulletBlock(
                          title: 'Competencias desarrolladas',
                          items: competencies,
                        ),
                      ),
                      _LearningSection(
                        title: 'Mastery Check',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puntaje inicial: ${intFrom(masteryCheck['initial_score'])}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cleanText(masteryCheck['recommendation'])
                                      .isNotEmpty
                                  ? cleanText(masteryCheck['recommendation'])
                                  : 'Completa las actividades para medir tu dominio inicial.',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String initialChapterId({
    required Map<String, dynamic> audiobook,
    required Map<String, dynamic> progress,
    required bool continueFromProgress,
  }) {
    final bookChapters = audiobookService.chapterListFrom(
      audiobook['chapters'],
    );
    if (bookChapters.isEmpty) return '';

    final progressChapterId = cleanText(progress['current_chapter_id']);
    final hasProgressChapter = bookChapters.any(
      (chapter) => cleanText(chapter['chapter_id']) == progressChapterId,
    );

    if (continueFromProgress && hasProgressChapter) return progressChapterId;

    final completed = stringListFrom(progress['completed_chapters']).toSet();
    final firstPending = bookChapters.firstWhere(
      (chapter) => !completed.contains(cleanText(chapter['chapter_id'])),
      orElse: () => bookChapters.first,
    );
    return cleanText(firstPending['chapter_id']);
  }

  List<Map<String, dynamic>> get chapters {
    return audiobookService.chapterListFrom(selectedAudioBook['chapters']);
  }

  Map<String, dynamic>? get selectedChapter {
    if (selectedChapterId.isEmpty) return null;

    for (final chapter in chapters) {
      if (cleanText(chapter['chapter_id']) == selectedChapterId) {
        return chapter;
      }
    }

    return null;
  }

  bool get selectedChapterHasAudio {
    final chapter = selectedChapter;
    if (chapter == null) return false;
    return cleanText(chapter['audio_url']).isNotEmpty;
  }

  Duration get simulatedTickDuration {
    final safeSpeed = playbackSpeed <= 0 ? 1.0 : playbackSpeed;
    return Duration(milliseconds: (1000 / safeSpeed).round());
  }

  String backendVoiceProfile(String value) {
    // TODO AudioBook v5: mapear a voces comerciales cuando el backend las soporte.
    return 'standard';
  }

  String voiceLabel(String value) {
    switch (value) {
      case 'calm':
        return 'Voz: calmada';
      case 'energetic':
        return 'Voz: energética';
      case 'teacher':
        return 'Voz: docente';
      default:
        return 'Voz: estándar';
    }
  }

  String playbackModeLabel(Map<String, dynamic>? chapter) {
    if (chapter == null) return 'Sin capítulo';
    return cleanText(chapter['audio_url']).isNotEmpty
        ? 'Audio real'
        : 'Simulado';
  }

  StudyResult? resultForAudioBookId(String audiobookId) {
    final cleanId = audiobookId.trim();
    for (final result in savedAudioBooks) {
      final audiobook = audiobookService.decodeAudioBook(result);
      final id = cleanText(audiobook['audiobook_id']).isNotEmpty
          ? cleanText(audiobook['audiobook_id'])
          : result.documentId;
      if (id == cleanId) return result;
    }
    return null;
  }

  Map<String, dynamic> audioBookFromResult(StudyResult result) {
    final audiobook = audiobookService.decodeAudioBook(result);
    return {
      ...audiobook,
      'audiobook_id': cleanText(audiobook['audiobook_id']).isNotEmpty
          ? cleanText(audiobook['audiobook_id'])
          : result.documentId,
    };
  }

  String currentChapterTitleFor(
    Map<String, dynamic> audiobook,
    Map<String, dynamic> progress,
  ) {
    final chapterId = cleanText(progress['current_chapter_id']);
    final bookChapters = audiobookService.chapterListFrom(
      audiobook['chapters'],
    );
    final chapter = bookChapters.firstWhere(
      (item) => cleanText(item['chapter_id']) == chapterId,
      orElse: () => bookChapters.isNotEmpty ? bookChapters.first : {},
    );

    return chapter.isEmpty
        ? 'Sin capítulo seleccionado'
        : audiobookService.chapterTitle(chapter);
  }

  String cleanText(dynamic value) => value?.toString().trim() ?? '';

  String firstCleanTextFrom(List<dynamic> values) {
    for (final value in values) {
      final text = cleanText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> stringListFrom(dynamic raw) {
    if (raw is List) {
      return raw.map(cleanText).where((item) => item.isNotEmpty).toList();
    }

    final text = cleanText(raw);
    return text.isEmpty ? [] : [text];
  }

  int intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'Sin fecha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> saveLearningQuizAnswer({
    required Map<String, dynamic> chapter,
    required List<Map<String, dynamic>> miniQuiz,
    required int questionIndex,
    required String selectedAnswer,
  }) async {
    final audiobookId = cleanText(selectedAudioBook['audiobook_id']);
    final chapterId = cleanText(chapter['chapter_id']);

    if (audiobookId.isEmpty || chapterId.isEmpty || miniQuiz.isEmpty) return;

    var score = 0;
    for (var index = 0; index < miniQuiz.length; index++) {
      final question = miniQuiz[index];
      final key = '${chapterId}_$index';
      final answer =
          index == questionIndex ? selectedAnswer : (quizAnswers[key] ?? '');
      final correctAnswer = cleanText(question['correct_answer']);

      if (answer.isNotEmpty &&
          correctAnswer.isNotEmpty &&
          answer == correctAnswer) {
        score++;
      }
    }

    final competencies = audiobookService.learningPackCompetencies(chapter);

    await learningProgressService.saveQuizResult(
      audiobookId: audiobookId,
      chapterId: chapterId,
      score: score,
      total: miniQuiz.length,
      competencies: competencies,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedBookChapters = chapters;
    final completedChapters = stringListFrom(
      selectedProgress['completed_chapters'],
    );
    final completion = intFrom(selectedProgress['completion_percentage']);
    final currentChapter = selectedChapter;
    final currentChapterDuration = currentChapter == null
        ? 0
        : audiobookService.chapterDurationSeconds(currentChapter);
    final progressItems = savedProgressByAudioBookId.values.toList();
    final activeProgressItems = progressService.activeProgressItems(
      progressItems,
    );
    final continueProgress = activeProgressItems.isNotEmpty
        ? activeProgressItems.first
        : <String, dynamic>{};
    final continueResult = continueProgress.isEmpty
        ? null
        : resultForAudioBookId(cleanText(continueProgress['audiobook_id']));
    final recentResults = savedAudioBooks
        .where((result) {
          final audiobook = audioBookFromResult(result);
          final progress = savedProgressByAudioBookId[
                  cleanText(audiobook['audiobook_id'])] ??
              {};
          return cleanText(progress['last_played_at']).isNotEmpty;
        })
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Libro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio Libro',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Convierte tus documentos o temas en audio libros educativos.',
                  style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escucha, practica y consulta al Tutor IA desde cada capítulo.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed('dashboard'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Volver al Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (continueResult != null)
            _ContinueListeningSection(
              result: continueResult,
              audiobook: audioBookFromResult(continueResult),
              progress: continueProgress,
              chapterTitle: currentChapterTitleFor(
                audioBookFromResult(continueResult),
                continueProgress,
              ),
              onContinue: () => openAudioBook(
                continueResult,
                continueFromProgress: true,
              ),
              cleanText: cleanText,
              intFrom: intFrom,
            ),
          if (continueResult != null) const SizedBox(height: 18),
          if (selectedAudioBook.isNotEmpty && selectedChapterId.isNotEmpty)
            _MiniPlayer(
              audiobookTitle: audiobookService.titleFromAudioBook(
                selectedAudioBook,
              ),
              chapterTitle: currentChapter == null
                  ? 'Capítulo'
                  : audiobookService.chapterTitle(currentChapter),
              status: isPlaying ? 'Reproduciendo' : 'Pausado',
              mode: playbackModeLabel(currentChapter),
              currentPositionSeconds: currentPositionSeconds,
              currentChapterDuration: currentChapterDuration,
              playbackSpeed: playbackSpeed,
              onSpeedChanged: updatePlaybackSpeed,
              onResume: resumeSelectedChapter,
              onPause: pausePlayback,
              onRestart: restartChapter,
              onComplete: () => completeSelectedChapter(showMessage: true),
              onNext: goToNextChapter,
              isPlaying: isPlaying,
              formatDuration: formatDuration,
            ),
          if (selectedAudioBook.isNotEmpty && selectedChapterId.isNotEmpty)
            const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear experiencia de audio aprendizaje',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Texto / contenido académico',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                _VoiceSelector(
                  selectedVoiceProfile: selectedVoiceProfile,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedVoiceProfile = value);
                  },
                  voiceLabel: voiceLabel,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: isGenerating ? null : generateAudioBook,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    isGenerating
                        ? 'Generando audio libro...'
                        : 'Generar Audio Libro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SavedAudioBooksSection(
            savedAudioBooks: savedAudioBooks,
            isLoading: isLoadingSavedAudioBooks,
            progressByAudioBookId: savedProgressByAudioBookId,
            audiobookService: audiobookService,
            onOpen: (result) => openAudioBook(result),
            onContinue: (result) => openAudioBook(
              result,
              continueFromProgress: true,
            ),
            cleanText: cleanText,
            intFrom: intFrom,
            formatDate: formatDate,
          ),
          const SizedBox(height: 18),
          _RecentAudioBooksSection(
            recentAudioBooks: recentResults,
            progressByAudioBookId: savedProgressByAudioBookId,
            audiobookService: audiobookService,
            onContinue: (result) => openAudioBook(
              result,
              continueFromProgress: true,
            ),
            cleanText: cleanText,
            intFrom: intFrom,
          ),
          const SizedBox(height: 18),
          if (isGenerating)
            const SectionCard(
              child: Text(
                'Generando audio libro...',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else if (selectedAudioBook.isNotEmpty)
            _AudioBookResult(
              audiobook: selectedAudioBook,
              chapters: selectedBookChapters,
              currentChapterId: selectedChapterId,
              currentPositionSeconds: currentPositionSeconds,
              currentChapterDuration: currentChapterDuration,
              isPlaying: isPlaying,
              playbackSpeed: playbackSpeed,
              onSpeedChanged: updatePlaybackSpeed,
              completion: completion,
              completedChapters: completedChapters,
              onPlay: playChapter,
              generatingAudioChapterIds: generatingAudioChapterIds,
              generatingLearningPackChapterIds:
                  generatingLearningPackChapterIds,
              chapterAudioErrors: chapterAudioErrors,
              chapterLearningPackErrors: chapterLearningPackErrors,
              onResume: resumeSelectedChapter,
              onPause: pausePlayback,
              onRestart: restartChapter,
              onComplete: () => completeSelectedChapter(showMessage: true),
              onNext: goToNextChapter,
              onGenerateAudio: generateAudioForChapter,
              onGenerateLearningPack: generateLearningPackForChapter,
              onLearningPack: showLearningPack,
              onTranscript: showTranscript,
              onTutor: openVoiceTutorForChapter,
              onVoiceTutor: (chapter) => openVoiceTutorForChapter(
                chapter,
                startWithVoice: true,
              ),
              stringListFrom: stringListFrom,
              cleanText: cleanText,
              intFrom: intFrom,
              formatDuration: formatDuration,
              chapterDurationSeconds: audiobookService.chapterDurationSeconds,
            ),
        ],
      ),
    );
  }
}

class _SavedAudioBooksSection extends StatelessWidget {
  final List<StudyResult> savedAudioBooks;
  final bool isLoading;
  final Map<String, Map<String, dynamic>> progressByAudioBookId;
  final AudiobookService audiobookService;
  final ValueChanged<StudyResult> onOpen;
  final ValueChanged<StudyResult> onContinue;
  final String Function(dynamic value) cleanText;
  final int Function(dynamic value) intFrom;
  final String Function(String value) formatDate;

  const _SavedAudioBooksSection({
    required this.savedAudioBooks,
    required this.isLoading,
    required this.progressByAudioBookId,
    required this.audiobookService,
    required this.onOpen,
    required this.onContinue,
    required this.cleanText,
    required this.intFrom,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Audio Libros',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator()
          else if (savedAudioBooks.isEmpty)
            const LaunchEmptyState(
              title: 'Crea tu primer AudioBook',
              message:
                  'Escribe un tema arriba para activar audio, actividades y recomendaciones.',
              icon: Icons.headphones_outlined,
            )
          else
            ...savedAudioBooks.map(
              (result) {
                final audiobook = audiobookService.decodeAudioBook(result);
                final audiobookId =
                    cleanText(audiobook['audiobook_id']).isNotEmpty
                        ? cleanText(audiobook['audiobook_id'])
                        : result.documentId;
                final progress = progressByAudioBookId[audiobookId] ?? {};
                final title = audiobookService.titleFromAudioBook(audiobook);
                final description = audiobookService.shortDescription(
                  audiobook,
                );
                final chapterCount = audiobookService.chapterCount(audiobook);
                final durationLabel = audiobookService.estimatedDurationLabel(
                  audiobook,
                );
                final completion = intFrom(progress['completion_percentage']);
                final status = audiobookService.progressStatusLabel(progress);
                final audioCount = audiobookService.audioReadyChapterCount(
                  audiobook,
                );
                final lastAccess =
                    cleanText(progress['last_played_at']).isNotEmpty
                        ? formatDate(cleanText(progress['last_played_at']))
                        : formatDate(result.createdAt);

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.textMuted.withValues(alpha: 0.22),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('$chapterCount capítulos')),
                              Chip(label: Text(durationLabel)),
                              Chip(label: Text('Progreso $completion%')),
                              Chip(label: Text(status)),
                              Chip(label: Text('Último acceso: $lastAccess')),
                              if (audioCount > 0)
                                Chip(
                                  label: Text('Audio real: $audioCount'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completion.clamp(0, 100) / 100,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => onOpen(result),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Abrir'),
                              ),
                              FilledButton.icon(
                                onPressed: () => onContinue(result),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Continuar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ContinueListeningSection extends StatelessWidget {
  final StudyResult result;
  final Map<String, dynamic> audiobook;
  final Map<String, dynamic> progress;
  final String chapterTitle;
  final VoidCallback onContinue;
  final String Function(dynamic value) cleanText;
  final int Function(dynamic value) intFrom;

  const _ContinueListeningSection({
    required this.result,
    required this.audiobook,
    required this.progress,
    required this.chapterTitle,
    required this.onContinue,
    required this.cleanText,
    required this.intFrom,
  });

  @override
  Widget build(BuildContext context) {
    final title = cleanText(audiobook['title']).isNotEmpty
        ? cleanText(audiobook['title'])
        : 'Audio Libro';
    final completion = intFrom(progress['completion_percentage']);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continuar escuchando',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapterTitle,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: completion.clamp(0, 100) / 100),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text('$completion% completado')),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentAudioBooksSection extends StatelessWidget {
  final List<StudyResult> recentAudioBooks;
  final Map<String, Map<String, dynamic>> progressByAudioBookId;
  final AudiobookService audiobookService;
  final ValueChanged<StudyResult> onContinue;
  final String Function(dynamic value) cleanText;
  final int Function(dynamic value) intFrom;

  const _RecentAudioBooksSection({
    required this.recentAudioBooks,
    required this.progressByAudioBookId,
    required this.audiobookService,
    required this.onContinue,
    required this.cleanText,
    required this.intFrom,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escuchado recientemente',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (recentAudioBooks.isEmpty)
            const Text(
              'Escucha un capítulo y aquí podrás retomarlo rápidamente.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...recentAudioBooks.map((result) {
              final audiobook = audiobookService.decodeAudioBook(result);
              final audiobookId =
                  cleanText(audiobook['audiobook_id']).isNotEmpty
                      ? cleanText(audiobook['audiobook_id'])
                      : result.documentId;
              final progress = progressByAudioBookId[audiobookId] ?? {};
              final completion = intFrom(progress['completion_percentage']);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  audiobookService.titleFromAudioBook(audiobook),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '$completion% completado',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                trailing: TextButton(
                  onPressed: () => onContinue(result),
                  child: const Text('Continuar'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final String audiobookTitle;
  final String chapterTitle;
  final String status;
  final String mode;
  final int currentPositionSeconds;
  final int currentChapterDuration;
  final double playbackSpeed;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onResume;
  final Future<void> Function() onPause;
  final Future<void> Function() onRestart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onNext;
  final bool isPlaying;
  final String Function(int seconds) formatDuration;

  const _MiniPlayer({
    required this.audiobookTitle,
    required this.chapterTitle,
    required this.status,
    required this.mode,
    required this.currentPositionSeconds,
    required this.currentChapterDuration,
    required this.playbackSpeed,
    required this.onSpeedChanged,
    required this.onResume,
    required this.onPause,
    required this.onRestart,
    required this.onComplete,
    required this.onNext,
    required this.isPlaying,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentChapterDuration <= 0
        ? 0.0
        : (currentPositionSeconds / currentChapterDuration).clamp(0.0, 1.0);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mini player',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            audiobookTitle,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapterTitle,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(status)),
              Chip(label: Text(mode)),
              Chip(label: Text('${playbackSpeed}x')),
              Chip(
                label: Text(
                  '${formatDuration(currentPositionSeconds)} / '
                  '${formatDuration(currentChapterDuration)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          _SpeedSelector(
            playbackSpeed: playbackSpeed,
            onSpeedChanged: onSpeedChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isPlaying ? onPause : onResume,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(isPlaying ? 'Pausar' : 'Reproducir'),
              ),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Reiniciar'),
              ),
              OutlinedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Completar'),
              ),
              OutlinedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  final double playbackSpeed;
  final ValueChanged<double> onSpeedChanged;

  const _SpeedSelector({
    required this.playbackSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    const speeds = [0.75, 1.0, 1.25, 1.5];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Velocidad:',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        ...speeds.map(
          (speed) => ChoiceChip(
            label: Text('${speed}x'),
            selected: playbackSpeed == speed,
            onSelected: (_) => onSpeedChanged(speed),
          ),
        ),
      ],
    );
  }
}

class _VoiceSelector extends StatelessWidget {
  final String selectedVoiceProfile;
  final ValueChanged<String?> onChanged;
  final String Function(String value) voiceLabel;

  const _VoiceSelector({
    required this.selectedVoiceProfile,
    required this.onChanged,
    required this.voiceLabel,
  });

  @override
  Widget build(BuildContext context) {
    const voices = ['standard', 'calm', 'energetic', 'teacher'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          voiceLabel(selectedVoiceProfile),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: voices.map(
            (voice) {
              final label = voiceLabel(voice).replaceFirst('Voz: ', '');
              return ChoiceChip(
                label: Text(label),
                selected: selectedVoiceProfile == voice,
                onSelected: (_) => onChanged(voice),
              );
            },
          ).toList(),
        ),
      ],
    );
  }
}

class _AudioBookResult extends StatelessWidget {
  final Map<String, dynamic> audiobook;
  final List<Map<String, dynamic>> chapters;
  final String currentChapterId;
  final int currentPositionSeconds;
  final int currentChapterDuration;
  final bool isPlaying;
  final double playbackSpeed;
  final int completion;
  final List<String> completedChapters;
  final Set<String> generatingAudioChapterIds;
  final Set<String> generatingLearningPackChapterIds;
  final Map<String, String> chapterAudioErrors;
  final Map<String, String> chapterLearningPackErrors;
  final ValueChanged<Map<String, dynamic>> onPlay;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onResume;
  final Future<void> Function() onPause;
  final Future<void> Function() onRestart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onNext;
  final ValueChanged<Map<String, dynamic>> onGenerateAudio;
  final ValueChanged<Map<String, dynamic>> onGenerateLearningPack;
  final ValueChanged<Map<String, dynamic>> onLearningPack;
  final ValueChanged<Map<String, dynamic>> onTranscript;
  final ValueChanged<Map<String, dynamic>> onTutor;
  final ValueChanged<Map<String, dynamic>> onVoiceTutor;
  final List<String> Function(dynamic raw) stringListFrom;
  final String Function(dynamic value) cleanText;
  final int Function(dynamic value) intFrom;
  final String Function(int seconds) formatDuration;
  final int Function(Map<String, dynamic> chapter) chapterDurationSeconds;

  const _AudioBookResult({
    required this.audiobook,
    required this.chapters,
    required this.currentChapterId,
    required this.currentPositionSeconds,
    required this.currentChapterDuration,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.completion,
    required this.completedChapters,
    required this.generatingAudioChapterIds,
    required this.generatingLearningPackChapterIds,
    required this.chapterAudioErrors,
    required this.chapterLearningPackErrors,
    required this.onPlay,
    required this.onSpeedChanged,
    required this.onResume,
    required this.onPause,
    required this.onRestart,
    required this.onComplete,
    required this.onNext,
    required this.onGenerateAudio,
    required this.onGenerateLearningPack,
    required this.onLearningPack,
    required this.onTranscript,
    required this.onTutor,
    required this.onVoiceTutor,
    required this.stringListFrom,
    required this.cleanText,
    required this.intFrom,
    required this.formatDuration,
    required this.chapterDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final title = cleanText(audiobook['title']);
    final description = cleanText(audiobook['description']);
    final duration = intFrom(audiobook['estimated_duration_minutes']);
    final currentChapterProgress = currentChapterDuration <= 0
        ? 0.0
        : (currentPositionSeconds / currentChapterDuration).clamp(0.0, 1.0);
    final status = completion >= 100
        ? 'Completado'
        : completion > 0 || currentPositionSeconds > 0
            ? 'En progreso'
            : 'No iniciado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Audio Libro' : title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description.isEmpty
                    ? 'Experiencia de audio aprendizaje generada.'
                    : description,
                style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(label: Text('Duración estimada: $duration min')),
                  Chip(label: Text('Capítulos: ${chapters.length}')),
                  Chip(label: Text('Progreso: $completion%')),
                  Chip(
                    label: Text(
                      '${completedChapters.length}/${chapters.length} completados',
                    ),
                  ),
                  Chip(label: Text(status)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: completion.clamp(0, 100) / 100),
              const SizedBox(height: 16),
              _PlaybackPanel(
                currentChapterId: currentChapterId,
                currentPositionSeconds: currentPositionSeconds,
                currentChapterDuration: currentChapterDuration,
                currentChapterProgress: currentChapterProgress,
                isPlaying: isPlaying,
                playbackSpeed: playbackSpeed,
                onSpeedChanged: onSpeedChanged,
                onResume: onResume,
                onPause: onPause,
                onRestart: onRestart,
                onComplete: onComplete,
                onNext: onNext,
                formatDuration: formatDuration,
              ),
              const SizedBox(height: 12),
              _BulletBlock(
                title: 'Objetivos de aprendizaje',
                items: stringListFrom(audiobook['learning_objectives']),
              ),
              _BulletBlock(
                title: 'Conceptos clave',
                items: stringListFrom(audiobook['key_concepts']),
              ),
              _BulletBlock(
                title: 'Preguntas de repaso',
                items: stringListFrom(audiobook['review_questions']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Capítulos',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...chapters.map(
          (chapter) {
            final chapterId = cleanText(chapter['chapter_id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AudioBookChapterCard(
                chapter: chapter,
                isCurrent: chapterId == currentChapterId,
                isCompleted: completedChapters.contains(chapterId),
                isGeneratingAudio:
                    generatingAudioChapterIds.contains(chapterId),
                hasAudioError: chapterAudioErrors.containsKey(chapterId),
                isGeneratingLearningPack:
                    generatingLearningPackChapterIds.contains(chapterId),
                hasLearningPackError:
                    chapterLearningPackErrors.containsKey(chapterId),
                currentPositionSeconds:
                    chapterId == currentChapterId ? currentPositionSeconds : 0,
                durationSeconds: chapterDurationSeconds(chapter),
                onListen: () => onPlay(chapter),
                onGenerateAudio: () => onGenerateAudio(chapter),
                onGenerateLearningPack: () => onGenerateLearningPack(chapter),
                onLearningPack: () => onLearningPack(chapter),
                onTranscript: () => onTranscript(chapter),
                onTutor: () => onTutor(chapter),
                onVoiceTutor: () => onVoiceTutor(chapter),
                stringListFrom: stringListFrom,
                cleanText: cleanText,
                intFrom: intFrom,
                formatDuration: formatDuration,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlaybackPanel extends StatelessWidget {
  final String currentChapterId;
  final int currentPositionSeconds;
  final int currentChapterDuration;
  final double currentChapterProgress;
  final bool isPlaying;
  final double playbackSpeed;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onResume;
  final Future<void> Function() onPause;
  final Future<void> Function() onRestart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onNext;
  final String Function(int seconds) formatDuration;

  const _PlaybackPanel({
    required this.currentChapterId,
    required this.currentPositionSeconds,
    required this.currentChapterDuration,
    required this.currentChapterProgress,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.onSpeedChanged,
    required this.onResume,
    required this.onPause,
    required this.onRestart,
    required this.onComplete,
    required this.onNext,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (currentChapterId.isEmpty) {
      return const Text(
        'Selecciona un capítulo para iniciar.',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isPlaying ? 'Reproduciendo' : 'En pausa',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatDuration(currentPositionSeconds)} / '
                  '${formatDuration(currentChapterDuration)}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: currentChapterProgress),
            const SizedBox(height: 12),
            _SpeedSelector(
              playbackSpeed: playbackSpeed,
              onSpeedChanged: onSpeedChanged,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: isPlaying ? onPause : onResume,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(isPlaying ? 'Pausar' : 'Reproducir'),
                ),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reiniciar capítulo'),
                ),
                OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Marcar completado'),
                ),
                OutlinedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Siguiente capítulo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioBookChapterCard extends StatelessWidget {
  final Map<String, dynamic> chapter;
  final bool isCurrent;
  final bool isCompleted;
  final bool isGeneratingAudio;
  final bool hasAudioError;
  final bool isGeneratingLearningPack;
  final bool hasLearningPackError;
  final int currentPositionSeconds;
  final int durationSeconds;
  final VoidCallback onListen;
  final VoidCallback onGenerateAudio;
  final VoidCallback onGenerateLearningPack;
  final VoidCallback onLearningPack;
  final VoidCallback onTranscript;
  final VoidCallback onTutor;
  final VoidCallback onVoiceTutor;
  final List<String> Function(dynamic raw) stringListFrom;
  final String Function(dynamic value) cleanText;
  final int Function(dynamic value) intFrom;
  final String Function(int seconds) formatDuration;

  const _AudioBookChapterCard({
    required this.chapter,
    required this.isCurrent,
    required this.isCompleted,
    required this.isGeneratingAudio,
    required this.hasAudioError,
    required this.isGeneratingLearningPack,
    required this.hasLearningPackError,
    required this.currentPositionSeconds,
    required this.durationSeconds,
    required this.onListen,
    required this.onGenerateAudio,
    required this.onGenerateLearningPack,
    required this.onLearningPack,
    required this.onTranscript,
    required this.onTutor,
    required this.onVoiceTutor,
    required this.stringListFrom,
    required this.cleanText,
    required this.intFrom,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final number = intFrom(chapter['chapter_number']);
    final title = cleanText(chapter['title']);
    final summary = cleanText(chapter['summary']);
    final hasAudio = cleanText(chapter['audio_url']).isNotEmpty;
    final hasLearningPack = chapter['learning_pack'] is Map;
    final learningPack = hasLearningPack
        ? Map<String, dynamic>.from(chapter['learning_pack'] as Map)
        : <String, dynamic>{};
    final hasFlashcards = learningPack['flashcards'] is List &&
        (learningPack['flashcards'] as List).isNotEmpty;
    final hasMiniQuiz = learningPack['mini_quiz'] is List &&
        (learningPack['mini_quiz'] as List).isNotEmpty;
    final audioState = isGeneratingAudio
        ? 'Generando audio'
        : hasAudioError
            ? 'Error al generar audio'
            : hasAudio
                ? 'Audio listo'
                : 'Sin audio';
    final learningState = isGeneratingLearningPack
        ? 'Generando actividades'
        : hasLearningPackError
            ? 'Error al generar actividades'
            : hasLearningPack
                ? 'Actividades listas'
                : 'Sin actividades';
    final progress = durationSeconds <= 0
        ? 0.0
        : (currentPositionSeconds / durationSeconds).clamp(0.0, 1.0);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(number <= 0 ? '-' : '$number')),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.isEmpty ? 'Capítulo' : title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isCompleted)
                const Chip(label: Text('Completado'))
              else if (isCurrent)
                const Chip(label: Text('En progreso')),
              Chip(label: Text(audioState)),
              Chip(label: Text(learningState)),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text(
            '${formatDuration(currentPositionSeconds)} / '
            '${formatDuration(durationSeconds)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _BulletBlock(
            title: 'Conceptos clave',
            items: stringListFrom(chapter['key_concepts']),
          ),
          _BulletBlock(
            title: 'Preguntas de reflexión',
            items: stringListFrom(chapter['reflection_questions']),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onListen,
                icon: Icon(
                  hasAudio ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  currentPositionSeconds > 0
                      ? 'Continuar escuchando'
                      : 'Escuchar',
                ),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingAudio ? null : onGenerateAudio,
                icon: isGeneratingAudio
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.graphic_eq_rounded),
                label: Text(
                  hasAudio
                      ? 'Regenerar audio'
                      : isGeneratingAudio
                          ? 'Generando audio...'
                          : 'Generar audio',
                ),
              ),
              if (!hasLearningPack)
                OutlinedButton.icon(
                  onPressed:
                      isGeneratingLearningPack ? null : onGenerateLearningPack,
                  icon: isGeneratingLearningPack
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.quiz_rounded),
                  label: Text(
                    isGeneratingLearningPack
                        ? 'Generando actividades...'
                        : 'Generar actividades',
                  ),
                ),
              if (hasLearningPack && !hasFlashcards && !hasMiniQuiz)
                OutlinedButton.icon(
                  onPressed: onLearningPack,
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('Ver actividades'),
                ),
              if (hasFlashcards)
                OutlinedButton.icon(
                  onPressed: onLearningPack,
                  icon: const Icon(Icons.style_rounded),
                  label: const Text('Repasar flashcards'),
                ),
              if (hasMiniQuiz)
                OutlinedButton.icon(
                  onPressed: onLearningPack,
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('Hacer mini quiz'),
                ),
              OutlinedButton.icon(
                onPressed: onTranscript,
                icon: const Icon(Icons.article_rounded),
                label: const Text('Ver transcripción'),
              ),
              OutlinedButton.icon(
                onPressed: onTutor,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Preguntar al Tutor IA'),
              ),
              OutlinedButton.icon(
                onPressed: onVoiceTutor,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text('Preguntar por voz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _LearningSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  final String front;
  final String back;
  final String hint;
  final bool revealed;
  final VoidCallback onReveal;

  const _FlashcardTile({
    required this.front,
    required this.back,
    required this.hint,
    required this.revealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.textMuted.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flashcards',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                front.isEmpty ? 'Concepto' : front,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              if (hint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Pista: $hint',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
              const SizedBox(height: 8),
              if (revealed)
                Text(
                  back.isEmpty ? 'Sin respuesta disponible.' : back,
                  style: const TextStyle(color: AppTheme.textMuted),
                )
              else
                OutlinedButton(
                  onPressed: onReveal,
                  child: const Text('Ver respuesta'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizQuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final String selectedAnswer;
  final String Function(dynamic value) cleanText;
  final ValueChanged<String> onSelect;

  const _QuizQuestionTile({
    required this.question,
    required this.selectedAnswer,
    required this.cleanText,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question['options'] is List
        ? (question['options'] as List)
            .map(cleanText)
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];
    final correctAnswer = cleanText(question['correct_answer']);
    final answered = selectedAnswer.isNotEmpty;
    final isCorrect = answered && selectedAnswer == correctAnswer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cleanText(question['question']).isEmpty
                ? 'Pregunta'
                : cleanText(question['question']),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map(
              (option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: selectedAnswer == option,
                  onSelected: (_) => onSelect(option),
                );
              },
            ).toList(),
          ),
          if (answered) ...[
            Text(
              isCorrect ? 'Correcto' : 'Incorrecto',
              style: TextStyle(
                color: isCorrect ? AppTheme.success : AppTheme.warning,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cleanText(question['explanation']).isEmpty
                  ? 'Revisa el resumen del capítulo para reforzar esta idea.'
                  : cleanText(question['explanation']),
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  final String title;
  final List<String> items;

  const _BulletBlock({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          ...items.take(5).map(
                (item) => Text(
                  '• $item',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
