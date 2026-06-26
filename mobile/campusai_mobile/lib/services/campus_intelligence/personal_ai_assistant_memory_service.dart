import '../learning_engine/student_intelligence_service.dart';
import '../voice_intelligence/voice_memory_service.dart';
import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';

/// Keeps a compact, editable profile for coaching and planning context.
class PersonalAiAssistantMemoryService {
  static const String resultType = 'assistant_memory';
  static const String latestDocumentId = 'assistant_memory_latest';

  final VoiceMemoryService voiceMemoryService;
  final StudentIntelligenceService intelligenceService;
  final EnterpriseResultRepository repository;

  const PersonalAiAssistantMemoryService({
    this.voiceMemoryService = const VoiceMemoryService(),
    this.intelligenceService = const StudentIntelligenceService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<AssistantMemory> buildMemory(
      {List<String> preferredStudyHours = const []}) async {
    try {
      final existing = await getMemory();
      final intelligence = await intelligenceService.analyzeStudent();
      final recent = await voiceMemoryService.summarizeMemory();
      final difficulties = {
        ...existing?.difficulties ?? const <String>[],
        ...intelligence.weaknesses,
        ...intelligence.weakCompetencies,
      }.where((item) => item.trim().isNotEmpty).take(8).toList();
      final memory = AssistantMemory(
        updatedAt: DateTime.now(),
        preferredTone: existing?.preferredTone ?? 'supportive',
        language: existing?.language ?? 'es',
        preferredStudyHours: preferredStudyHours.isNotEmpty
            ? preferredStudyHours
            : existing?.preferredStudyHours ?? const [],
        favoriteSubjects: existing?.favoriteSubjects ??
            intelligence.strongCompetencies.take(5).toList(),
        difficulties: difficulties,
        objectives: {
          ...existing?.objectives ?? const <String>[],
          if (recent.isNotEmpty) recent,
        }.take(5).toList(),
        learningStyle:
            existing?.learningStyle ?? _learningStyle(intelligence.level),
      );
      await saveMemory(memory);
      return memory;
    } catch (_) {
      return AssistantMemory.empty();
    }
  }

  Future<void> saveMemory(AssistantMemory memory) => repository.save(
        documentId: latestDocumentId,
        type: resultType,
        payload: memory.toJson(),
        createdAt: memory.updatedAt,
      );

  Future<AssistantMemory?> getMemory() async {
    final raw = await repository.load(
        documentId: latestDocumentId, type: resultType, maxAge: Duration.zero);
    return raw == null ? null : AssistantMemory.fromJson(raw);
  }

  String _learningStyle(String level) =>
      level == 'Avanzado' ? 'active_recall' : 'guided_practice';
}
