import 'dart:io';

class SecurityFinding {
  final String path;
  final String pattern;
  final String severity;
  final String description;
  const SecurityFinding(
    this.path,
    this.pattern, {
    this.severity = 'medium',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'pattern': pattern,
        'severity': severity,
        'description': description,
      };
}

class SecurityScanReport {
  final DateTime generatedAt;
  final List<SecurityFinding> findings;

  const SecurityScanReport({
    required this.generatedAt,
    this.findings = const [],
  });

  bool get passed =>
      findings.where((finding) => finding.severity == 'high').isEmpty;

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'passed': passed,
        'findings': findings.map((finding) => finding.toJson()).toList(),
      };
}

class SecurityScanService {
  static const patterns = [
    'sk_test',
    'sk_live',
    'OPENAI_API_KEY',
    'STRIPE_SECRET_KEY',
    'JWT_SECRET',
    'BEGIN PRIVATE KEY',
    'access_token',
    'refresh_token'
  ];
  Future<List<SecurityFinding>> scan(Directory root) async {
    final found = <SecurityFinding>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || _ignored(entity.path)) {
        continue;
      }
      final name = entity.path.split('/').last;
      if (name == '.env') {
        found.add(SecurityFinding(
          entity.path,
          '.env',
          severity: 'high',
          description: 'Archivo .env presente en árbol revisado.',
        ));
      }
      if (_isSuspiciousPath(entity.path)) {
        found.add(SecurityFinding(
          entity.path,
          'suspicious_path',
          severity: 'low',
          description: 'Ruta sensible o archivo de ejemplo requiere revisión.',
        ));
      }
      try {
        final text = await entity.readAsString();
        for (final pattern in patterns) {
          if (text.contains(pattern)) {
            found.add(SecurityFinding(
              entity.path,
              _redactPattern(pattern),
              severity: _severity(pattern),
              description: 'Patrón sensible detectado sin exponer valor.',
            ));
          }
        }
        if (RegExp("password\\s*[:=]\\s*[\"']?[^\"'\\s]+", caseSensitive: false)
            .hasMatch(text)) {
          found.add(SecurityFinding(
            entity.path,
            'password_pattern',
            severity: 'medium',
            description: 'Posible password en texto plano.',
          ));
        }
      } catch (_) {}
    }
    return found;
  }

  Future<SecurityScanReport> scanReport(Directory root) async =>
      SecurityScanReport(
          generatedAt: DateTime.now(), findings: await scan(root));

  bool _ignored(String path) =>
      path.contains('/.venv/') ||
      path.contains('/build/') ||
      path.contains('/.dart_tool/') ||
      path.contains('/node_modules/');

  bool _isSuspiciousPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('/secrets/') ||
        lower.endsWith('.pem') ||
        lower.endsWith('.key') ||
        lower.contains('sample_user') ||
        lower.contains('personal_data');
  }

  String _redactPattern(String pattern) =>
      pattern.length <= 4 ? pattern : '${pattern.substring(0, 4)}...';

  String _severity(String pattern) => pattern.contains('SECRET') ||
          pattern.contains('PRIVATE') ||
          pattern.startsWith('sk_')
      ? 'high'
      : 'medium';
}
