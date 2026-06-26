import 'performance_readiness_models.dart';

class CacheCoverageAnalyzer {
  const CacheCoverageAnalyzer();

  PerformanceFinding analyze({
    required List<String> cachedAreas,
    required List<String> criticalAreas,
  }) {
    final missing =
        criticalAreas.where((area) => !cachedAreas.contains(area)).toList();
    return PerformanceFinding(
      area: 'Cache',
      severity: missing.isEmpty ? 'low' : 'medium',
      message: missing.isEmpty
          ? 'Áreas críticas cubiertas por cache.'
          : 'Falta cache en: ${missing.join(', ')}.',
      recommendation: missing.isEmpty
          ? 'Mantener TTL por dominio.'
          : 'Agregar snapshots TTL para áreas faltantes.',
    );
  }
}
