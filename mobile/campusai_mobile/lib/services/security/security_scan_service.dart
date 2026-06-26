import 'dart:io';

class SecurityFinding {
  final String path;
  final String pattern;
  const SecurityFinding(this.path, this.pattern);
}

class SecurityScanService {
  static const patterns = [
    'sk_test',
    'sk_live',
    'OPENAI_API_KEY',
    'STRIPE_SECRET_KEY',
    'JWT_SECRET'
  ];
  Future<List<SecurityFinding>> scan(Directory root) async {
    final found = <SecurityFinding>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || entity.path.contains('/.venv/')) {
        continue;
      }
      final name = entity.path.split('/').last;
      if (name == '.env') {
        found.add(SecurityFinding(entity.path, '.env tracked or present'));
      }
      try {
        final text = await entity.readAsString();
        for (final pattern in patterns) {
          if (text.contains(pattern)) {
            found.add(SecurityFinding(entity.path, pattern));
          }
        }
      } catch (_) {}
    }
    return found;
  }
}
