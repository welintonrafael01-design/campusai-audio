library;

class Institution {
  final String id;
  final String name;
  final String role;
  final List<Campus> campuses;
  const Institution(
      {this.id = '',
      this.name = '',
      this.role = 'Institution',
      this.campuses = const []});
  factory Institution.fromJson(Map<String, dynamic> j) => Institution(
      id: _t(j['id']),
      name: _t(j['name']),
      role: _t(j['role'], 'Institution'),
      campuses: _ms(j['campuses']).map(Campus.fromJson).toList());
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'campuses': campuses.map((x) => x.toJson()).toList()
      };
}

class Campus {
  final String id;
  final String name;
  final List<Faculty> faculties;
  const Campus({this.id = '', this.name = '', this.faculties = const []});
  factory Campus.fromJson(Map<String, dynamic> j) => Campus(
      id: _t(j['id']),
      name: _t(j['name']),
      faculties: _ms(j['faculties']).map(Faculty.fromJson).toList());
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'faculties': faculties.map((x) => x.toJson()).toList()
      };
}

class Faculty {
  final String id;
  final String name;
  final List<Department> departments;
  const Faculty({this.id = '', this.name = '', this.departments = const []});
  factory Faculty.fromJson(Map<String, dynamic> j) => Faculty(
      id: _t(j['id']),
      name: _t(j['name']),
      departments: _ms(j['departments']).map(Department.fromJson).toList());
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'departments': departments.map((x) => x.toJson()).toList()
      };
}

class Department {
  final String id;
  final String name;
  const Department({this.id = '', this.name = ''});
  factory Department.fromJson(Map<String, dynamic> j) =>
      Department(id: _t(j['id']), name: _t(j['name']));
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AcademicProgram {
  final String id;
  final String name;
  final String departmentId;
  const AcademicProgram({this.id = '', this.name = '', this.departmentId = ''});
  factory AcademicProgram.fromJson(Map<String, dynamic> j) => AcademicProgram(
      id: _t(j['id']),
      name: _t(j['name']),
      departmentId: _t(j['department_id']));
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'department_id': departmentId};
}

class InstitutionMetrics {
  final int risk;
  final int progress;
  final int retention;
  final int dropout;
  final int aiUsage;
  final int audiobookUsage;
  final int tutorUsage;
  final int voiceUsage;
  final int learningPacks;
  final int plannerUsage;
  final int engagement;
  const InstitutionMetrics(
      {this.risk = 0,
      this.progress = 0,
      this.retention = 0,
      this.dropout = 0,
      this.aiUsage = 0,
      this.audiobookUsage = 0,
      this.tutorUsage = 0,
      this.voiceUsage = 0,
      this.learningPacks = 0,
      this.plannerUsage = 0,
      this.engagement = 0});
  factory InstitutionMetrics.fromJson(Map<String, dynamic> j) =>
      InstitutionMetrics(
          risk: _i(j['risk']),
          progress: _i(j['progress']),
          retention: _i(j['retention']),
          dropout: _i(j['dropout']),
          aiUsage: _i(j['ai_usage']),
          audiobookUsage: _i(j['audiobook_usage']),
          tutorUsage: _i(j['tutor_usage']),
          voiceUsage: _i(j['voice_usage']),
          learningPacks: _i(j['learning_packs']),
          plannerUsage: _i(j['planner_usage']),
          engagement: _i(j['engagement']));
  Map<String, dynamic> toJson() => {
        'risk': risk,
        'progress': progress,
        'retention': retention,
        'dropout': dropout,
        'ai_usage': aiUsage,
        'audiobook_usage': audiobookUsage,
        'tutor_usage': tutorUsage,
        'voice_usage': voiceUsage,
        'learning_packs': learningPacks,
        'planner_usage': plannerUsage,
        'engagement': engagement
      };
}

class InstitutionAlert {
  final String title;
  final String message;
  final String severity;
  const InstitutionAlert(
      {this.title = '', this.message = '', this.severity = 'info'});
  factory InstitutionAlert.fromJson(Map<String, dynamic> j) => InstitutionAlert(
      title: _t(j['title']),
      message: _t(j['message']),
      severity: _t(j['severity'], 'info'));
  Map<String, dynamic> toJson() =>
      {'title': title, 'message': message, 'severity': severity};
}

class InstitutionPrediction {
  final int successProbability;
  final int riskProbability;
  final String recommendation;
  const InstitutionPrediction(
      {this.successProbability = 0,
      this.riskProbability = 0,
      this.recommendation = ''});
  factory InstitutionPrediction.fromJson(Map<String, dynamic> j) =>
      InstitutionPrediction(
          successProbability: _i(j['success_probability']),
          riskProbability: _i(j['risk_probability']),
          recommendation: _t(j['recommendation']));
  Map<String, dynamic> toJson() => {
        'success_probability': successProbability,
        'risk_probability': riskProbability,
        'recommendation': recommendation
      };
}

class InstitutionDashboard {
  final DateTime updatedAt;
  final Institution institution;
  final InstitutionMetrics metrics;
  final List<InstitutionAlert> alerts;
  final InstitutionPrediction prediction;
  const InstitutionDashboard(
      {required this.updatedAt,
      this.institution = const Institution(),
      this.metrics = const InstitutionMetrics(),
      this.alerts = const [],
      this.prediction = const InstitutionPrediction()});
  factory InstitutionDashboard.empty() =>
      InstitutionDashboard(updatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory InstitutionDashboard.fromJson(Map<String, dynamic> j) =>
      InstitutionDashboard(
          updatedAt: DateTime.tryParse(_t(j['updated_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          institution: Institution.fromJson(_m(j['institution'])),
          metrics: InstitutionMetrics.fromJson(_m(j['metrics'])),
          alerts: _ms(j['alerts']).map(InstitutionAlert.fromJson).toList(),
          prediction: InstitutionPrediction.fromJson(_m(j['prediction'])));
  Map<String, dynamic> toJson() => {
        'updated_at': updatedAt.toIso8601String(),
        'institution': institution.toJson(),
        'metrics': metrics.toJson(),
        'alerts': alerts.map((x) => x.toJson()).toList(),
        'prediction': prediction.toJson()
      };
}

int _i(dynamic v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;
String _t(dynamic v, [String f = '']) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? f : s;
}

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _ms(dynamic v) => v is List
    ? v.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList()
    : <Map<String, dynamic>>[];
