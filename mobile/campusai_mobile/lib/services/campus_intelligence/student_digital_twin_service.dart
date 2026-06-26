import '../learning_engine/streak_service.dart';
import '../learning_engine/student_intelligence_service.dart';
import 'campus_snapshot_repository.dart';
import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';
import 'personal_ai_assistant_memory_service.dart';
import 'productivity_service.dart';

/// Consolidates current learning, habits, motivation, and risk into one profile.
class StudentDigitalTwinService {
  static const String resultType = 'digital_twin';
  static const String latestDocumentId = 'digital_twin_latest';

  final StudentIntelligenceService intelligenceService;
  final StreakService streakService;
  final CampusSnapshotRepository snapshotRepository;
  final ProductivityService productivityService;
  final PersonalAiAssistantMemoryService memoryService;
  final EnterpriseResultRepository repository;

  const StudentDigitalTwinService({
    this.intelligenceService = const StudentIntelligenceService(),
    this.streakService = const StreakService(),
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.productivityService = const ProductivityService(),
    this.memoryService = const PersonalAiAssistantMemoryService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<StudentDigitalTwin> buildTwin({
    ProductivitySnapshot? productivity,
  }) async {
    try {
      final intelligence = await intelligenceService.analyzeStudent();
      final streak = await streakService.calculateStreak();
      final campus = await snapshotRepository.getLatestSnapshot();
      final resolvedProductivity =
          productivity ?? await productivityService.buildSnapshot();
      final memory = await memoryService.getMemory();
      final motivation = _score([
        streak.currentStreakDays * 14,
        resolvedProductivity.focus.score,
        campus?.engagementScore ?? 0,
      ]);
      final twin = StudentDigitalTwin(
        updatedAt: DateTime.now(),
        knowledgeScore: intelligence.masteryPercentage,
        habitScore: resolvedProductivity.consistency.score,
        motivationScore: motivation,
        risk: campus?.academicRisk ?? intelligence.risk,
        strengths: intelligence.strengths.take(5).toList(),
        weaknesses: intelligence.weaknesses.take(5).toList(),
        objectives: memory?.objectives ?? const [],
        currentState: _state(intelligence.masteryPercentage, motivation),
      );
      await repository.save(
          documentId: latestDocumentId,
          type: resultType,
          payload: twin.toJson(),
          createdAt: twin.updatedAt);
      return twin;
    } catch (_) {
      return StudentDigitalTwin.empty();
    }
  }

  Future<StudentDigitalTwin?> getLatestTwin() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: resultType);
    return raw == null ? null : StudentDigitalTwin.fromJson(raw);
  }

  int _score(List<num> values) => values.isEmpty
      ? 0
      : (values.reduce((a, b) => a + b) / values.length).round().clamp(0, 100);
  String _state(int mastery, int motivation) =>
      mastery >= 75 && motivation >= 60
          ? 'En avance sostenido'
          : motivation < 35
              ? 'Requiere reactivación'
              : 'En consolidación';
}
