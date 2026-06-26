import 'performance_readiness_models.dart';

class HeavyServiceAnalyzer {
  const HeavyServiceAnalyzer();

  List<PerformanceFinding> analyze(List<String> services) => services
      .where((service) => service.toLowerCase().contains('enterprise'))
      .map(
        (service) => PerformanceFinding(
          area: service,
          severity: 'low',
          message: 'Servicio potencialmente pesado detectado.',
          recommendation: 'Usar cache local y ejecución bajo demanda.',
        ),
      )
      .toList();
}
