import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/study_result.dart';
import 'academic_engine/academic_resource_repository.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'cloud_api_service.dart';
import 'study_result_service.dart';

enum AudioBookSyncStatus {
  local,
  syncing,
  synced,
  syncFailed,
}

extension AudioBookSyncStatusValue on AudioBookSyncStatus {
  String get storageValue => switch (this) {
        AudioBookSyncStatus.local => 'local',
        AudioBookSyncStatus.syncing => 'syncing',
        AudioBookSyncStatus.synced => 'synced',
        AudioBookSyncStatus.syncFailed => 'sync_failed',
      };
}

class AudioBookSaveResult {
  final String documentId;
  final bool cloudSynced;
  final AudioBookSyncStatus syncStatus;
  final Map<String, dynamic> audiobook;

  const AudioBookSaveResult({
    required this.documentId,
    required this.cloudSynced,
    required this.syncStatus,
    required this.audiobook,
  });
}

class AudiobookService {
  static const String resultType = 'audiobook';

  const AudiobookService();

  Future<Map<String, dynamic>> generateAudiobookFromText({
    required String text,
    int maxChapters = 6,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('No hay texto suficiente para crear el audiolibro.');
    }

    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/audiobook',
    ).replace(
      queryParameters: {
        'text': cleanText,
        'max_chapters': maxChapters.toString(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }

  Future<Map<String, dynamic>> generateFromText({
    required String title,
    required String text,
    String sourceMode = 'solo',
    String sourceType = 'text',
    String sourceDocumentId = '',
    String courseId = '',
    String courseName = '',
    String unitId = '',
    String unitTopic = '',
    String language = 'es',
    String voiceProfile = 'standard',
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('No hay texto suficiente para generar Audio Libro.');
    }

    try {
      final response = await ApiService.generateAudioBookFromText(
        title: title,
        text: cleanText,
        sourceMode: sourceMode,
        sourceType: sourceType,
        sourceDocumentId: sourceDocumentId,
        courseId: courseId,
        courseName: courseName,
        unitId: unitId,
        unitTopic: unitTopic,
        language: language,
        voiceProfile: voiceProfile,
      );

      final raw = response['audiobook'];
      if (raw is Map) {
        return {
          ...normalizeAudioBookPayload(
            Map<String, dynamic>.from(raw),
            fallbackTitle: title,
            fallbackText: cleanText,
            sourceMode: sourceMode,
            sourceType: sourceType,
            sourceDocumentId: sourceDocumentId,
            courseId: courseId,
            courseName: courseName,
            unitId: unitId,
            unitTopic: unitTopic,
            language: language,
            voiceProfile: voiceProfile,
          ),
          'generation_source': 'backend',
        };
      }
    } catch (_) {
      // Fallback local para que el MVP funcione aunque el backend/IA falle.
    }

    return fallbackAudioBookFromText(
      title: title,
      text: cleanText,
      sourceMode: sourceMode,
      sourceType: sourceType,
      sourceDocumentId: sourceDocumentId,
      courseId: courseId,
      courseName: courseName,
      unitId: unitId,
      unitTopic: unitTopic,
      language: language,
      voiceProfile: voiceProfile,
    );
  }

  Future<String> saveAudioBook(Map<String, dynamic> audiobook) async {
    final result = await saveAudioBookWithStatus(audiobook);
    return result.documentId;
  }

  Future<AudioBookSaveResult> saveAudioBookWithStatus(
    Map<String, dynamic> audiobook, {
    Future<void> Function()? cloudSave,
  }) async {
    final documentId = documentIdForAudioBook(audiobook);
    final syncUpdatedAt = DateTime.now().toIso8601String();

    final payload = Map<String, dynamic>.from(audiobook)
      ..remove('_last_audio_generation_failed')
      ..remove('_last_audio_generation_chapter_id')
      ..remove('_last_learning_pack_generation_failed')
      ..remove('_last_learning_pack_generation_chapter_id')
      ..remove('_cloud_sync_pending')
      ..['audiobook_id'] = documentId
      ..['sync_status'] = AudioBookSyncStatus.synced.storageValue
      ..['sync_updated_at'] = syncUpdatedAt;
    final syncingPayload = {
      ...payload,
      'sync_status': AudioBookSyncStatus.syncing.storageValue,
    };

    final cloudSynced = await AcademicResourceRepository.saveResource(
      documentId: documentId,
      type: resultType,
      content: jsonEncode(payload),
      localContent: jsonEncode(syncingPayload),
      cloudDebugLabel: 'audio libro',
      cloudSave: cloudSave,
    );

    final finalStatus = cloudSynced
        ? AudioBookSyncStatus.synced
        : AudioBookSyncStatus.syncFailed;
    final finalPayload = {
      ...payload,
      'sync_status': finalStatus.storageValue,
      'sync_updated_at': DateTime.now().toIso8601String(),
    };

    await StudyResultService.saveResult(
      StudyResult(
        documentId: documentId,
        type: resultType,
        content: jsonEncode(finalPayload),
        createdAt: syncUpdatedAt,
      ),
    );

    return AudioBookSaveResult(
      documentId: documentId,
      cloudSynced: cloudSynced,
      syncStatus: finalStatus,
      audiobook: finalPayload,
    );
  }

  String documentIdForAudioBook(Map<String, dynamic> audiobook) {
    final unitId = cleanText(audiobook['unit_id']);
    if (unitId.isNotEmpty) return '${unitId}_audiobook';

    final sourceDocumentId = cleanText(audiobook['source_document_id']);
    if (sourceDocumentId.isNotEmpty) {
      return sourceDocumentId.endsWith('_audiobook')
          ? sourceDocumentId
          : '${sourceDocumentId}_audiobook';
    }

    final audiobookId = cleanText(audiobook['audiobook_id']);
    return audiobookId.isNotEmpty
        ? audiobookId
        : 'audiobook_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<List<StudyResult>> getAudioBooks({
    Future<List<dynamic>> Function()? cloudLoader,
  }) async {
    final localResults = await StudyResultService.getResultsByType(resultType);
    final resultsById = {
      for (final result in localResults) result.documentId: result,
    };

    if (cloudLoader == null && !AuthService.isLoggedIn) {
      return localResults;
    }

    try {
      final cloudItems = await (cloudLoader ??
          () => CloudApiService.getStudyResults(type: resultType))();

      for (final item in cloudItems) {
        final cloudResult = studyResultFromCloud(item);
        if (cloudResult == null) continue;

        final local = resultsById[cloudResult.documentId];
        if (local != null && syncStatusFromResult(local) == 'sync_failed') {
          continue;
        }

        resultsById[cloudResult.documentId] = cloudResult;
        await StudyResultService.saveResult(cloudResult);
      }
    } catch (_) {
      // Offline/cloud failure: the local library remains fully available.
    }

    final results = resultsById.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Future<StudyResult?> getAudioBook(
    String documentId, {
    Future<Map<String, dynamic>?> Function()? cloudLoader,
  }) async {
    final local = await StudyResultService.getResult(
      documentId: documentId,
      type: resultType,
    );
    if (local != null) return local;
    if (cloudLoader == null && !AuthService.isLoggedIn) return null;

    try {
      final cloudItem = await (cloudLoader ??
          () => CloudApiService.getStudyResult(
                documentId: documentId,
                type: resultType,
              ))();
      final cloudResult = studyResultFromCloud(cloudItem);
      if (cloudResult == null) return null;
      await StudyResultService.saveResult(cloudResult);
      return cloudResult;
    } catch (_) {
      return null;
    }
  }

  Future<StudyResult?> getAudioBookById(String documentId) {
    return getAudioBook(documentId);
  }

  StudyResult? studyResultFromCloud(dynamic raw) {
    if (raw is! Map) return null;
    final item = Map<String, dynamic>.from(raw);
    final documentId = cleanText(item['document_id']).isNotEmpty
        ? cleanText(item['document_id'])
        : cleanText(item['documentId']);
    final type = cleanText(item['type']);
    final content = cleanText(item['content']);
    if (documentId.isEmpty || type != resultType || content.isEmpty) {
      return null;
    }

    var hydratedContent = content;
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        hydratedContent = jsonEncode({
          ...Map<String, dynamic>.from(decoded),
          'audiobook_id': documentId,
          'sync_status': AudioBookSyncStatus.synced.storageValue,
        });
      }
    } catch (_) {}

    return StudyResult(
      documentId: documentId,
      type: resultType,
      content: hydratedContent,
      createdAt: firstCleanText([
        item['updated_at'],
        item['created_at'],
        item['createdAt'],
        DateTime.now().toIso8601String(),
      ]),
    );
  }

  String syncStatusFromResult(StudyResult result) {
    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map) return cleanText(decoded['sync_status']);
    } catch (_) {}
    return AudioBookSyncStatus.local.storageValue;
  }

  Map<String, dynamic> decodeAudioBook(StudyResult result) {
    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        final raw = Map<String, dynamic>.from(decoded);
        return normalizeAudioBookPayload(
          raw,
          fallbackTitle: titleFromAudioBook(raw),
          fallbackText: cleanText(raw['description']),
          sourceMode: cleanText(raw['source_mode']).isNotEmpty
              ? cleanText(raw['source_mode'])
              : 'solo',
          sourceType: cleanText(raw['source_type']).isNotEmpty
              ? cleanText(raw['source_type'])
              : 'text',
          sourceDocumentId: cleanText(raw['source_document_id']),
          courseId: cleanText(raw['course_id']),
          courseName: cleanText(raw['course_name']),
          unitId: cleanText(raw['unit_id']),
          unitTopic: cleanText(raw['unit_topic']),
          language: cleanText(raw['language']).isNotEmpty
              ? cleanText(raw['language'])
              : 'es',
          voiceProfile: cleanText(raw['voice_profile']).isNotEmpty
              ? cleanText(raw['voice_profile'])
              : 'standard',
        );
      }
    } catch (_) {
      // Contenido local inválido: se devuelve estructura mínima segura.
    }

    return {
      'audiobook_id': result.documentId,
      'title': 'Audio Libro',
      'description': '',
      'chapters': <Map<String, dynamic>>[],
      'learning_objectives': <String>[],
      'key_concepts': <String>[],
      'review_questions': <String>[],
      'created_at': result.createdAt,
    };
  }

  int chapterDurationSeconds(Map<String, dynamic> chapter) {
    final explicitDuration = intFrom(chapter['duration_seconds']);
    if (explicitDuration > 0) return explicitDuration;

    final text = [
      cleanText(chapter['script']),
      cleanText(chapter['transcript']),
      cleanText(chapter['summary']),
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final words = text.split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
    final estimated = (words.length / 2).ceil();

    return estimated.clamp(30, 600);
  }

  int chapterCount(Map<String, dynamic> audiobook) {
    return chapterListFrom(audiobook['chapters']).length;
  }

  String titleFromAudioBook(Map<String, dynamic> audiobook) {
    final title = cleanText(audiobook['title']);
    if (title.isNotEmpty) return title;

    final unitTopic = cleanText(audiobook['unit_topic']);
    return unitTopic.isNotEmpty ? 'Audio Libro - $unitTopic' : 'Audio Libro';
  }

  int audioReadyChapterCount(Map<String, dynamic> audiobook) {
    return chapterListFrom(audiobook['chapters'])
        .where((chapter) => cleanText(chapter['audio_url']).isNotEmpty)
        .length;
  }

  bool hasAnyAudio(Map<String, dynamic> audiobook) {
    return audioReadyChapterCount(audiobook) > 0;
  }

  String progressStatusLabel(Map<String, dynamic> progress) {
    final completion = intFrom(progress['completion_percentage']);
    if (completion >= 100) return 'Completado';
    if (completion > 0 || intFrom(progress['current_position_seconds']) > 0) {
      return 'En progreso';
    }
    return 'No iniciado';
  }

  List<StudyResult> sortedAudioBooksByProgress(
    List<StudyResult> results,
    Map<String, Map<String, dynamic>> progressByAudioBookId,
  ) {
    final sorted = [...results];
    sorted.sort((a, b) {
      final audioBookA = decodeAudioBook(a);
      final audioBookB = decodeAudioBook(b);
      final idA = cleanText(audioBookA['audiobook_id']).isNotEmpty
          ? cleanText(audioBookA['audiobook_id'])
          : a.documentId;
      final idB = cleanText(audioBookB['audiobook_id']).isNotEmpty
          ? cleanText(audioBookB['audiobook_id'])
          : b.documentId;
      final dateA = _sortDate(
        cleanText(progressByAudioBookId[idA]?['last_played_at']),
        a.createdAt,
      );
      final dateB = _sortDate(
        cleanText(progressByAudioBookId[idB]?['last_played_at']),
        b.createdAt,
      );

      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  String shortDescription(Map<String, dynamic> audiobook) {
    final description = cleanText(audiobook['description']);
    if (description.length <= 120) return description;
    return '${description.substring(0, 117)}...';
  }

  String estimatedDurationLabel(Map<String, dynamic> audiobook) {
    final minutes = intFrom(audiobook['estimated_duration_minutes']);
    if (minutes <= 0) return 'Duración pendiente';
    return '$minutes min';
  }

  String chapterTitle(Map<String, dynamic> chapter) {
    final title = cleanText(chapter['title']);
    if (title.isNotEmpty) return title;

    final number = intFrom(chapter['chapter_number']);
    return number > 0 ? 'Capítulo $number' : 'Capítulo';
  }

  String chapterSummary(Map<String, dynamic> chapter) {
    final summary = cleanText(chapter['summary']);
    if (summary.length <= 160) return summary;
    return '${summary.substring(0, 157)}...';
  }

  DateTime _sortDate(String primary, String fallback) {
    return DateTime.tryParse(primary) ??
        DateTime.tryParse(fallback) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<Map<String, dynamic>> generateChapterAudio({
    required Map<String, dynamic> audiobook,
    required String chapterId,
    String voiceProfile = 'standard',
  }) async {
    final audiobookId = cleanText(audiobook['audiobook_id']);
    final chapters = chapterListFrom(audiobook['chapters']);
    final chapter = chapters.firstWhere(
      (item) => cleanText(item['chapter_id']) == chapterId.trim(),
      orElse: () => <String, dynamic>{},
    );

    if (audiobookId.isEmpty || chapter.isEmpty) return audiobook;

    final script = [
      cleanText(chapter['script']),
      cleanText(chapter['transcript']),
      cleanText(chapter['summary']),
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');

    if (script.isEmpty) return audiobook;

    try {
      final response = await ApiService.generateAudioForAudioBookChapter(
        audiobookId: audiobookId,
        chapterId: chapterId,
        chapterTitle: cleanText(chapter['title']),
        script: script,
        voiceProfile: voiceProfile.trim().isNotEmpty
            ? voiceProfile.trim()
            : cleanText(audiobook['voice_profile']).isNotEmpty
                ? cleanText(audiobook['voice_profile'])
                : 'standard',
        language: cleanText(audiobook['language']).isNotEmpty
            ? cleanText(audiobook['language'])
            : 'es',
      );

      final audioUrl = cleanText(response['audio_url']);
      final durationSeconds = intFrom(response['duration_seconds']);
      if (audioUrl.isEmpty) {
        return {
          ...audiobook,
          '_last_audio_generation_failed': true,
          '_last_audio_generation_chapter_id': chapterId,
        };
      }

      final updated = updateChapterAudio(
        audiobook: audiobook,
        chapterId: chapterId,
        audioUrl: audioUrl,
        durationSeconds: durationSeconds > 0
            ? durationSeconds
            : chapterDurationSeconds(chapter),
      );

      final saveResult = await saveAudioBookWithStatus(updated);
      return {
        ...saveResult.audiobook,
        if (!saveResult.cloudSynced) '_cloud_sync_pending': true,
      };
    } catch (_) {
      return {
        ...audiobook,
        '_last_audio_generation_failed': true,
        '_last_audio_generation_chapter_id': chapterId,
      };
    }
  }

  Map<String, dynamic> updateChapterAudio({
    required Map<String, dynamic> audiobook,
    required String chapterId,
    required String audioUrl,
    required int durationSeconds,
  }) {
    final chapters = chapterListFrom(audiobook['chapters']).map((chapter) {
      if (cleanText(chapter['chapter_id']) != chapterId.trim()) {
        return chapter;
      }

      return {
        ...chapter,
        'audio_url': audioUrl,
        'duration_seconds': durationSeconds > 0
            ? durationSeconds
            : chapterDurationSeconds(chapter),
      };
    }).toList();

    return {
      ...audiobook,
      'chapters': chapters,
      'estimated_duration_minutes': chapters.fold<int>(
        0,
        (sum, chapter) => sum + (chapterDurationSeconds(chapter) / 60).ceil(),
      ),
    };
  }

  Future<Map<String, dynamic>> generateLearningPackForChapter({
    required Map<String, dynamic> audiobook,
    required String chapterId,
  }) async {
    final audiobookId = cleanText(audiobook['audiobook_id']);
    final chapters = chapterListFrom(audiobook['chapters']);
    final chapter = chapters.firstWhere(
      (item) => cleanText(item['chapter_id']) == chapterId.trim(),
      orElse: () => <String, dynamic>{},
    );

    if (audiobookId.isEmpty || chapter.isEmpty) return audiobook;

    final script = cleanText(chapter['script']);
    final transcript = cleanText(chapter['transcript']);
    final summary = cleanText(chapter['summary']);

    if ([script, transcript, summary].every((item) => item.isEmpty)) {
      return {
        ...audiobook,
        '_last_learning_pack_generation_failed': true,
        '_last_learning_pack_generation_chapter_id': chapterId,
      };
    }

    try {
      final response = await ApiService.generateLearningPackForAudioBookChapter(
        audiobookId: audiobookId,
        chapterId: chapterId,
        chapterTitle: chapterTitle(chapter),
        summary: summary,
        script: script,
        transcript: transcript,
        keyConcepts: stringListFrom(chapter['key_concepts']),
        language: cleanText(audiobook['language']).isNotEmpty
            ? cleanText(audiobook['language'])
            : 'es',
      );
      final raw = response['learning_pack'];
      if (raw is! Map) {
        return {
          ...audiobook,
          '_last_learning_pack_generation_failed': true,
          '_last_learning_pack_generation_chapter_id': chapterId,
        };
      }

      final learningPack = normalizeLearningPack(
        Map<String, dynamic>.from(raw),
        chapter,
      );
      final updated = updateChapterLearningPack(
        audiobook: audiobook,
        chapterId: chapterId,
        learningPack: learningPack,
      );

      final saveResult = await saveAudioBookWithStatus(updated);
      return {
        ...saveResult.audiobook,
        if (!saveResult.cloudSynced) '_cloud_sync_pending': true,
      };
    } catch (_) {
      return {
        ...audiobook,
        '_last_learning_pack_generation_failed': true,
        '_last_learning_pack_generation_chapter_id': chapterId,
      };
    }
  }

  Map<String, dynamic> updateChapterLearningPack({
    required Map<String, dynamic> audiobook,
    required String chapterId,
    required Map<String, dynamic> learningPack,
  }) {
    final chapters = chapterListFrom(audiobook['chapters']).map((chapter) {
      if (cleanText(chapter['chapter_id']) != chapterId.trim()) {
        return chapter;
      }

      return {
        ...chapter,
        'learning_pack': learningPack,
      };
    }).toList();

    return {
      ...audiobook,
      'chapters': chapters,
    };
  }

  bool hasLearningPack(Map<String, dynamic> chapter) {
    return learningPackFromChapter(chapter).isNotEmpty;
  }

  Map<String, dynamic> learningPackFromChapter(Map<String, dynamic> chapter) {
    final raw = chapter['learning_pack'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String learningPackSummary(Map<String, dynamic> chapter) {
    final learningPack = learningPackFromChapter(chapter);
    return cleanText(learningPack['summary']);
  }

  List<Map<String, dynamic>> learningPackFlashcards(
    Map<String, dynamic> chapter,
  ) {
    final raw = learningPackFromChapter(chapter)['flashcards'];
    if (raw is! List) return [];

    return raw.whereType<Map>().map((item) {
      final card = Map<String, dynamic>.from(item);
      return {
        'front': cleanText(card['front']),
        'back': cleanText(card['back']),
        'hint': cleanText(card['hint']),
      };
    }).toList();
  }

  List<Map<String, dynamic>> learningPackQuiz(Map<String, dynamic> chapter) {
    final raw = learningPackFromChapter(chapter)['mini_quiz'];
    if (raw is! List) return [];

    return raw.whereType<Map>().map((item) {
      final question = Map<String, dynamic>.from(item);
      return {
        'question': cleanText(question['question']),
        'options': stringListFrom(question['options']),
        'correct_answer': cleanText(question['correct_answer']),
        'explanation': cleanText(question['explanation']),
        'bloom_level': cleanText(question['bloom_level']).isNotEmpty
            ? cleanText(question['bloom_level'])
            : 'Comprender',
      };
    }).toList();
  }

  List<String> learningPackCompetencies(Map<String, dynamic> chapter) {
    return stringListFrom(learningPackFromChapter(chapter)['competencies']);
  }

  Map<String, dynamic> normalizeLearningPack(
    Map<String, dynamic> raw,
    Map<String, dynamic> chapter,
  ) {
    final fallback = fallbackLearningPack(chapter);
    final merged = {
      ...fallback,
      ...raw,
    };
    final flashcards = stringMapListFrom(merged['flashcards'])
        .map((card) {
          return {
            'front': cleanText(card['front']),
            'back': cleanText(card['back']),
            'hint': cleanText(card['hint']),
          };
        })
        .where((card) => cleanText(card['front']).isNotEmpty)
        .toList();
    final miniQuiz = stringMapListFrom(merged['mini_quiz'])
        .map((question) {
          return {
            'question': cleanText(question['question']),
            'options': stringListFrom(question['options']).take(4).toList(),
            'correct_answer': cleanText(question['correct_answer']),
            'explanation': cleanText(question['explanation']),
            'bloom_level': cleanText(question['bloom_level']).isNotEmpty
                ? cleanText(question['bloom_level'])
                : 'Comprender',
          };
        })
        .where((question) => cleanText(question['question']).isNotEmpty)
        .toList();

    return {
      ...merged,
      'chapter_id': cleanText(merged['chapter_id']).isNotEmpty
          ? cleanText(merged['chapter_id'])
          : cleanText(chapter['chapter_id']),
      'chapter_title': cleanText(merged['chapter_title']).isNotEmpty
          ? cleanText(merged['chapter_title'])
          : chapterTitle(chapter),
      'learning_pack_version':
          cleanText(merged['learning_pack_version']).isNotEmpty
              ? cleanText(merged['learning_pack_version'])
              : 'A',
      'estimated_study_minutes': intFrom(merged['estimated_study_minutes']),
      'difficulty': cleanText(merged['difficulty']).isNotEmpty
          ? cleanText(merged['difficulty'])
          : 'Media',
      'key_concepts': stringListFrom(merged['key_concepts']),
      'flashcards': flashcards.isNotEmpty ? flashcards : fallback['flashcards'],
      'mini_quiz': miniQuiz.isNotEmpty ? miniQuiz : fallback['mini_quiz'],
      'reflection_questions': stringListFrom(merged['reflection_questions']),
      'competencies': stringListFrom(merged['competencies']),
      'mastery_check': merged['mastery_check'] is Map
          ? Map<String, dynamic>.from(merged['mastery_check'] as Map)
          : fallback['mastery_check'],
      'created_at': cleanText(merged['created_at']).isNotEmpty
          ? cleanText(merged['created_at'])
          : DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> fallbackLearningPack(Map<String, dynamic> chapter) {
    final title = chapterTitle(chapter);
    final summary = [
      cleanText(chapter['summary']),
      cleanText(chapter['transcript']),
      cleanText(chapter['script']),
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final concepts = stringListFrom(chapter['key_concepts']).isNotEmpty
        ? stringListFrom(chapter['key_concepts'])
        : ['Idea principal', 'Conceptos clave', 'Aplicación práctica'];

    return {
      'chapter_id': cleanText(chapter['chapter_id']),
      'chapter_title': title,
      'learning_pack_version': 'A',
      'summary':
          summary.length > 500 ? '${summary.substring(0, 500)}...' : summary,
      'estimated_study_minutes': 10,
      'difficulty': 'Media',
      'key_concepts': concepts,
      'flashcards': concepts.take(5).map((concept) {
        return {
          'front': '¿Qué significa $concept?',
          'back': '$concept es una idea importante del capítulo $title.',
          'hint': 'Relaciona el concepto con el resumen del capítulo.',
        };
      }).toList(),
      'mini_quiz': [
        {
          'question': '¿Cuál es el objetivo principal de este capítulo?',
          'options': [
            'Comprender las ideas centrales',
            'Ignorar el contenido',
            'Memorizar sin analizar',
            'Evitar la reflexión',
          ],
          'correct_answer': 'Comprender las ideas centrales',
          'explanation':
              'El capítulo busca que comprendas sus ideas principales.',
          'bloom_level': 'Comprender',
        },
      ],
      'reflection_questions':
          stringListFrom(chapter['reflection_questions']).isNotEmpty
              ? stringListFrom(chapter['reflection_questions'])
              : ['¿Cómo aplicarías este capítulo en una situación real?'],
      'competencies': [
        'Comprensión conceptual',
        'Pensamiento crítico',
      ],
      'mastery_check': {
        'initial_score': 0,
        'status': 'Pendiente',
        'recommendation':
            'Estudia el resumen, revisa flashcards y responde el mini quiz.',
      },
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> normalizeAudioBookPayload(
    Map<String, dynamic> raw, {
    required String fallbackTitle,
    required String fallbackText,
    String sourceMode = 'solo',
    String sourceType = 'text',
    String sourceDocumentId = '',
    String courseId = '',
    String courseName = '',
    String unitId = '',
    String unitTopic = '',
    String language = 'es',
    String voiceProfile = 'standard',
  }) {
    final fallback = fallbackAudioBookFromText(
      title: fallbackTitle,
      text: fallbackText,
      sourceMode: sourceMode,
      sourceType: sourceType,
      sourceDocumentId: sourceDocumentId,
      courseId: courseId,
      courseName: courseName,
      unitId: unitId,
      unitTopic: unitTopic,
      language: language,
      voiceProfile: voiceProfile,
    );

    final chapters = chapterListFrom(raw['chapters']);

    return {
      ...fallback,
      ...raw,
      'audiobook_id': cleanText(raw['audiobook_id']).isNotEmpty
          ? cleanText(raw['audiobook_id'])
          : cleanText(fallback['audiobook_id']),
      'source_mode': cleanText(raw['source_mode']).isNotEmpty
          ? cleanText(raw['source_mode'])
          : sourceMode,
      'source_type': cleanText(raw['source_type']).isNotEmpty
          ? cleanText(raw['source_type'])
          : sourceType,
      'source_document_id': sourceDocumentId.trim().isNotEmpty
          ? sourceDocumentId.trim()
          : cleanText(raw['source_document_id']),
      'course_id': cleanText(raw['course_id']).isNotEmpty
          ? cleanText(raw['course_id'])
          : courseId,
      'course_name': cleanText(raw['course_name']).isNotEmpty
          ? cleanText(raw['course_name'])
          : courseName,
      'unit_id': cleanText(raw['unit_id']).isNotEmpty
          ? cleanText(raw['unit_id'])
          : unitId,
      'unit_topic': cleanText(raw['unit_topic']).isNotEmpty
          ? cleanText(raw['unit_topic'])
          : unitTopic,
      'title': cleanText(raw['title']).isNotEmpty
          ? cleanText(raw['title'])
          : cleanText(fallback['title']),
      'chapters': chapters.isNotEmpty ? chapters : fallback['chapters'],
      'learning_objectives': stringListFrom(raw['learning_objectives']),
      'key_concepts': stringListFrom(raw['key_concepts']),
      'review_questions': stringListFrom(raw['review_questions']),
      'sync_status': cleanText(raw['sync_status']).isNotEmpty
          ? cleanText(raw['sync_status'])
          : AudioBookSyncStatus.local.storageValue,
      'generation_source': cleanText(raw['generation_source']).isNotEmpty
          ? cleanText(raw['generation_source'])
          : cleanText(fallback['generation_source']),
      'created_at': cleanText(raw['created_at']).isNotEmpty
          ? cleanText(raw['created_at'])
          : DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> fallbackAudioBookFromText({
    required String title,
    required String text,
    String sourceMode = 'solo',
    String sourceType = 'text',
    String sourceDocumentId = '',
    String courseId = '',
    String courseName = '',
    String unitId = '',
    String unitTopic = '',
    String language = 'es',
    String voiceProfile = 'standard',
  }) {
    final cleanTitle = title.trim().isNotEmpty
        ? title.trim()
        : unitTopic.trim().isNotEmpty
            ? 'Audio Libro - ${unitTopic.trim()}'
            : 'Audio Libro';
    final chapters = splitText(text).asMap().entries.map((entry) {
      final number = entry.key + 1;
      final chapterText = entry.value;
      final chapterTitle = unitTopic.trim().isNotEmpty
          ? '${unitTopic.trim()} - Parte $number'
          : 'Capítulo $number';
      final script =
          'En este capítulo estudiaremos $chapterTitle.\n\n$chapterText';

      return {
        'chapter_id': 'chapter_$number',
        'chapter_number': number,
        'title': chapterTitle,
        'summary': chapterText.length > 280
            ? '${chapterText.substring(0, 280)}...'
            : chapterText,
        'script': script,
        'transcript': script,
        'audio_url': '',
        'duration_seconds': (script.length / 14).round().clamp(60, 1800),
        'key_concepts': <String>[],
        'reflection_questions': [
          '¿Cuál es la idea más importante de este capítulo?',
          '¿Cómo puedes aplicar este contenido en tu aprendizaje?',
        ],
      };
    }).toList();

    return {
      'audiobook_id': unitId.trim().isNotEmpty
          ? '${unitId.trim()}_audiobook'
          : sourceDocumentId.trim().isNotEmpty
              ? '${sourceDocumentId.trim()}_audiobook'
              : 'audiobook_${DateTime.now().millisecondsSinceEpoch}',
      'source_mode': sourceMode,
      'source_type': sourceType,
      'source_document_id': sourceDocumentId,
      'course_id': courseId,
      'course_name': courseName,
      'unit_id': unitId,
      'unit_topic': unitTopic,
      'title': cleanTitle,
      'description':
          'Audio libro educativo generado desde contenido académico.',
      'language': language,
      'voice_profile': voiceProfile,
      'sync_status': AudioBookSyncStatus.local.storageValue,
      'generation_source': 'local_fallback',
      'estimated_duration_minutes': chapters.fold<int>(
        0,
        (sum, chapter) =>
            sum + ((chapter['duration_seconds'] as int) / 60).ceil(),
      ),
      'chapters': chapters,
      'learning_objectives': <String>[],
      'key_concepts': <String>[],
      'review_questions': [
        'Resume el contenido en tus propias palabras.',
        'Identifica dos conceptos clave y explícalos con ejemplos.',
      ],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> chapterListFrom(dynamic raw) {
    if (raw is! List) return [];

    return raw
        .asMap()
        .entries
        .where((entry) => entry.value is Map)
        .map((entry) {
      final number = entry.key + 1;
      final item = Map<String, dynamic>.from(entry.value as Map);
      final script = cleanText(item['script']).isNotEmpty
          ? cleanText(item['script'])
          : cleanText(item['transcript']);

      return {
        'chapter_id': cleanText(item['chapter_id']).isNotEmpty
            ? cleanText(item['chapter_id'])
            : 'chapter_$number',
        'chapter_number': number,
        'title': cleanText(item['title']).isNotEmpty
            ? cleanText(item['title'])
            : 'Capítulo $number',
        'summary': cleanText(item['summary']),
        'script': script,
        'transcript': cleanText(item['transcript']).isNotEmpty
            ? cleanText(item['transcript'])
            : script,
        'audio_url': cleanText(item['audio_url']),
        'duration_seconds': intFrom(item['duration_seconds']),
        'key_concepts': stringListFrom(item['key_concepts']),
        'reflection_questions': stringListFrom(item['reflection_questions']),
        if (item['learning_pack'] is Map)
          'learning_pack': Map<String, dynamic>.from(
            item['learning_pack'] as Map,
          ),
      };
    }).toList();
  }

  List<String> splitText(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return [];

    final paragraphs = clean
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final source = paragraphs.isEmpty ? [clean] : paragraphs;
    final chapters = <String>[];
    var current = '';

    for (final paragraph in source) {
      if ((current.length + paragraph.length) <= 1800) {
        current = [current, paragraph]
            .where((item) => item.trim().isNotEmpty)
            .join('\n\n');
      } else {
        if (current.isNotEmpty) chapters.add(current);
        current = paragraph;
      }

      if (chapters.length >= 4) break;
    }

    if (current.isNotEmpty && chapters.length < 4) chapters.add(current);
    return chapters.isEmpty ? [clean] : chapters;
  }

  List<String> stringListFrom(dynamic raw) {
    if (raw is List) {
      return raw.map(cleanText).where((item) => item.isNotEmpty).toList();
    }

    final text = cleanText(raw);
    return text.isEmpty ? [] : [text];
  }

  List<Map<String, dynamic>> stringMapListFrom(dynamic raw) {
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String cleanText(dynamic value) => value?.toString().trim() ?? '';

  String firstCleanText(List<dynamic> values) {
    return values.map(cleanText).firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
  }
}
