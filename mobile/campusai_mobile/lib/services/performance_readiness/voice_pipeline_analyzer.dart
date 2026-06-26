import 'performance_readiness_models.dart';

class VoicePipelineAnalyzer {
  const VoicePipelineAnalyzer();

  PerformanceFinding analyze({bool streamingEnabled = false, int stages = 0}) =>
      PerformanceFinding(
        area: 'Voice Pipeline',
        severity: streamingEnabled ? 'medium' : 'low',
        message: 'Etapas: $stages. Streaming: $streamingEnabled.',
        recommendation: streamingEnabled
            ? 'Medir latencia antes de RC.'
            : 'Foundation sin streaming real, riesgo controlado.',
      );
}
