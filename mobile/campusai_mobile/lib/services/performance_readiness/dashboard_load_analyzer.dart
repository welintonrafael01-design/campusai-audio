import 'performance_readiness_models.dart';

class DashboardLoadAnalyzer {
  const DashboardLoadAnalyzer();

  PerformanceFinding analyze({int serviceCount = 0, bool usesCache = true}) {
    final heavy = serviceCount >= 8;
    return PerformanceFinding(
      area: 'Dashboard',
      severity: heavy && !usesCache ? 'medium' : 'low',
      message: 'Servicios cargados: $serviceCount. Cache: $usesCache.',
      recommendation: heavy
          ? 'Mantener carga diferida y cache de snapshots.'
          : 'Riesgo de carga controlado.',
    );
  }
}
