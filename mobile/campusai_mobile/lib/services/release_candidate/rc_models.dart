class ReleaseCandidateReport {
  final String version;
  final int score;
  final DateTime generatedAt;
  final List<RcModuleStatus> modules;
  final List<RcQualityGate> qualityGates;
  final List<RcRisk> risks;
  final List<RcChecklistItem> checklist;

  const ReleaseCandidateReport({
    this.version = 'RC1',
    this.score = 0,
    required this.generatedAt,
    this.modules = const [],
    this.qualityGates = const [],
    this.risks = const [],
    this.checklist = const [],
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'score': score,
        'generated_at': generatedAt.toIso8601String(),
        'modules': modules.map((item) => item.toJson()).toList(),
        'quality_gates': qualityGates.map((item) => item.toJson()).toList(),
        'risks': risks.map((item) => item.toJson()).toList(),
        'checklist': checklist.map((item) => item.toJson()).toList(),
      };
}

class RcModuleStatus {
  final String module;
  final String status;
  final int readiness;
  final List<String> notes;

  const RcModuleStatus({
    required this.module,
    this.status = 'ready',
    this.readiness = 100,
    this.notes = const [],
  });

  Map<String, dynamic> toJson() => {
        'module': module,
        'status': status,
        'readiness': readiness,
        'notes': notes,
      };
}

class RcQualityGate {
  final String name;
  final bool passed;
  final String evidence;

  const RcQualityGate({
    required this.name,
    this.passed = false,
    this.evidence = '',
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'passed': passed, 'evidence': evidence};
}

class RcRisk {
  final String area;
  final String severity;
  final String description;
  final String mitigation;

  const RcRisk({
    required this.area,
    this.severity = 'low',
    this.description = '',
    this.mitigation = '',
  });

  Map<String, dynamic> toJson() => {
        'area': area,
        'severity': severity,
        'description': description,
        'mitigation': mitigation,
      };
}

class RcChecklistItem {
  final String id;
  final String title;
  final bool completed;
  final String owner;

  const RcChecklistItem({
    required this.id,
    required this.title,
    this.completed = false,
    this.owner = 'release',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'owner': owner,
      };
}
