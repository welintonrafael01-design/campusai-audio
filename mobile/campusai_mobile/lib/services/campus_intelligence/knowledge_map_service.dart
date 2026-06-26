import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';
import 'learning_graph_enterprise_service.dart';

/// Derives what the student knows, needs to review, and should study next.
class KnowledgeMapService {
  static const String resultType = 'knowledge_map';
  static const String latestDocumentId = 'knowledge_map_latest';

  final LearningGraphEnterpriseService graphService;
  final EnterpriseResultRepository repository;

  const KnowledgeMapService({
    this.graphService = const LearningGraphEnterpriseService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<KnowledgeMap> buildKnowledgeMap({LearningRoadmap? roadmap}) async {
    try {
      final resolvedRoadmap = roadmap ?? await graphService.buildRoadmap();
      final dependentIds =
          resolvedRoadmap.edges.map((edge) => edge.fromNodeId).toSet();
      final concepts = resolvedRoadmap.nodes
          .map(
            (node) => KnowledgeConcept(
              nodeId: node.id,
              title: node.title,
              mastery: node.mastery,
              state: _stateFor(node.mastery, node.status),
              critical: resolvedRoadmap.difficultyMap.criticalNodeIds
                  .contains(node.id),
              unlocksOthers: dependentIds.contains(node.id),
            ),
          )
          .toList();
      final focus = concepts.where((concept) => concept.mastery < 70).toList()
        ..sort((a, b) {
          final aScore = (a.critical ? -100 : 0) + a.mastery;
          final bScore = (b.critical ? -100 : 0) + b.mastery;
          return aScore.compareTo(bScore);
        });
      final map = KnowledgeMap(
        generatedAt: DateTime.now(),
        concepts: concepts,
        tomorrowFocus: focus.map((concept) => concept.title).take(3).toList(),
        criticalConcepts: concepts
            .where((concept) => concept.critical || concept.unlocksOthers)
            .map((concept) => concept.title)
            .take(5)
            .toList(),
        summary: _summary(concepts, focus),
      );
      await repository.save(
        documentId: latestDocumentId,
        type: resultType,
        payload: map.toJson(),
        createdAt: map.generatedAt,
      );
      return map;
    } catch (_) {
      return KnowledgeMap.empty();
    }
  }

  Future<KnowledgeMap?> getLatestKnowledgeMap() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: resultType);
    return raw == null ? null : KnowledgeMap.fromJson(raw);
  }

  String _stateFor(int mastery, String status) {
    if (mastery >= 85 || status == 'mastered') return 'mastered';
    if (mastery >= 65) return 'known';
    if (mastery >= 35) return 'developing';
    return status == 'completed' ? 'forgotten' : 'needs_practice';
  }

  String _summary(
      List<KnowledgeConcept> concepts, List<KnowledgeConcept> focus) {
    if (concepts.isEmpty) {
      return 'Aún no hay conceptos suficientes para construir el mapa.';
    }
    final mastered = concepts.where((item) => item.state == 'mastered').length;
    if (focus.isEmpty) {
      return 'Dominas $mastered conceptos. Mantén una práctica corta de repaso.';
    }
    return 'Prioriza ${focus.first.title} y luego continúa con ${focus.skip(1).take(2).map((item) => item.title).join(', ')}.';
  }
}
