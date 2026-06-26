import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';
import 'learning_graph_service.dart';

/// Builds the typed learning graph used by recommendations and enterprise UI.
class LearningGraphEnterpriseService {
  static const String resultType = 'learning_graph';
  static const String latestDocumentId = 'learning_graph_latest';

  final LearningGraphService graphService;
  final EnterpriseResultRepository repository;

  const LearningGraphEnterpriseService({
    this.graphService = const LearningGraphService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<LearningRoadmap> buildRoadmap({bool preferCached = true}) async {
    if (preferCached) {
      final cached = await getLatestRoadmap();
      if (cached != null) return cached;
    }
    try {
      final graph = await graphService.buildGraph();
      final nodes = graph
          .map(
            (node) => LearningNode(
              id: node.id,
              title: node.title,
              type: node.type,
              mastery: node.mastery.clamp(0, 100),
              difficulty: _difficultyFor(node.mastery, node.type),
              status: node.status,
              competencies: node.relatedCompetencies,
              relatedNodeIds: node.dependencies,
            ),
          )
          .where((node) => node.id.isNotEmpty)
          .take(160)
          .toList();
      final edges = <LearningEdge>[];
      final dependencies = <LearningDependency>[];
      final nodeIds = nodes.map((node) => node.id).toSet();
      for (final node in nodes) {
        for (final dependency in node.relatedNodeIds) {
          if (!nodeIds.contains(dependency)) continue;
          final prerequisite =
              nodes.firstWhere((item) => item.id == dependency);
          final blocked = prerequisite.mastery < 50;
          edges.add(
            LearningEdge(
              fromNodeId: dependency,
              toNodeId: node.id,
              relation: 'prerequisite',
              strength: blocked ? 90 : 65,
            ),
          );
          dependencies.add(
            LearningDependency(
              nodeId: node.id,
              prerequisiteId: dependency,
              status: blocked ? 'blocked' : 'ready',
              recommendation: blocked
                  ? 'Refuerza ${prerequisite.title} antes de avanzar.'
                  : 'Puedes continuar hacia ${node.title}.',
            ),
          );
        }
      }
      final clusters = _clusters(nodes);
      final critical = nodes
          .where((node) => node.mastery < 50 && node.relatedNodeIds.isNotEmpty)
          .map((node) => node.id)
          .take(8)
          .toList();
      final roadmap = LearningRoadmap(
        generatedAt: DateTime.now(),
        nodes: nodes,
        edges: edges,
        clusters: clusters,
        dependencies: dependencies,
        recommendations: _recommendations(nodes, dependencies),
        difficultyMap: LearningDifficultyMap(
          byNodeId: {for (final node in nodes) node.id: node.difficulty},
          criticalNodeIds: critical,
        ),
      );
      await repository.save(
        documentId: latestDocumentId,
        type: resultType,
        payload: roadmap.toJson(),
        createdAt: roadmap.generatedAt,
      );
      return roadmap;
    } catch (_) {
      return LearningRoadmap.empty();
    }
  }

  Future<LearningRoadmap?> getLatestRoadmap() async {
    final raw = await repository.load(
      documentId: latestDocumentId,
      type: resultType,
    );
    return raw == null ? null : LearningRoadmap.fromJson(raw);
  }

  List<LearningCluster> _clusters(List<LearningNode> nodes) {
    final grouped = <String, List<LearningNode>>{};
    for (final node in nodes) {
      for (final competency in node.competencies) {
        grouped.putIfAbsent(competency, () => []).add(node);
      }
    }
    return grouped.entries
        .map(
          (entry) => LearningCluster(
            id: 'cluster_${_slug(entry.key)}',
            title: entry.key,
            mastery: entry.value.isEmpty
                ? 0
                : (entry.value
                            .map((node) => node.mastery)
                            .reduce((a, b) => a + b) /
                        entry.value.length)
                    .round(),
            nodeIds: entry.value.map((node) => node.id).toList(),
          ),
        )
        .take(40)
        .toList();
  }

  List<LearningRecommendation> _recommendations(
    List<LearningNode> nodes,
    List<LearningDependency> dependencies,
  ) {
    final blockedIds = dependencies
        .where((item) => item.status == 'blocked')
        .map((item) => item.prerequisiteId)
        .toSet();
    final candidates = [...nodes]
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    return candidates
        .where((node) => node.mastery < 80)
        .take(5)
        .map(
          (node) => LearningRecommendation(
            id: 'roadmap_${node.id}',
            title: 'Refuerza ${node.title}',
            description: blockedIds.contains(node.id)
                ? 'Es un prerrequisito para desbloquear contenido relacionado.'
                : 'Una práctica breve puede elevar tu dominio antes de avanzar.',
            nodeId: node.id,
            priority: blockedIds.contains(node.id) ? 1 : 2,
            estimatedMinutes: node.difficulty >= 4 ? 20 : 12,
          ),
        )
        .toList();
  }

  int _difficultyFor(int mastery, String type) {
    final baseline = type == 'competency' ? 3 : 2;
    return (baseline +
            (mastery < 40
                ? 2
                : mastery < 70
                    ? 1
                    : 0))
        .clamp(1, 5);
  }

  String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
