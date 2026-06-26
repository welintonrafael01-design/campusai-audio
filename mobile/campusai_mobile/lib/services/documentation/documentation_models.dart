class ServiceInventoryItem {
  final String name;
  final String module;
  final String responsibility;
  final bool localFirst;

  const ServiceInventoryItem({
    required this.name,
    required this.module,
    this.responsibility = '',
    this.localFirst = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'module': module,
        'responsibility': responsibility,
        'local_first': localFirst,
      };
}

class ModuleInventoryItem {
  final String name;
  final String status;
  final List<String> services;

  const ModuleInventoryItem({
    required this.name,
    this.status = 'ready',
    this.services = const [],
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'status': status, 'services': services};
}

class ReleaseNote {
  final String version;
  final DateTime date;
  final List<String> highlights;
  final List<String> knownRisks;

  const ReleaseNote({
    this.version = 'RC1',
    required this.date,
    this.highlights = const [],
    this.knownRisks = const [],
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'date': date.toIso8601String(),
        'highlights': highlights,
        'known_risks': knownRisks,
      };
}

class TechnicalDocumentation {
  final String title;
  final List<ModuleInventoryItem> modules;
  final List<ServiceInventoryItem> services;
  final List<String> dataFlows;
  final List<String> studyResultTypes;

  const TechnicalDocumentation({
    this.title = 'StudyBook AI Technical Documentation',
    this.modules = const [],
    this.services = const [],
    this.dataFlows = const [],
    this.studyResultTypes = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'modules': modules.map((item) => item.toJson()).toList(),
        'services': services.map((item) => item.toJson()).toList(),
        'data_flows': dataFlows,
        'study_result_types': studyResultTypes,
      };
}

class UserGuideSection {
  final String title;
  final List<String> steps;

  const UserGuideSection({required this.title, this.steps = const []});

  Map<String, dynamic> toJson() => {'title': title, 'steps': steps};
}
