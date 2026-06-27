import 'launch_models.dart';

/// Evaluates commercial preparation without reading or changing Billing.
class CommercialReadinessService {
  const CommercialReadinessService();

  CommercialReadiness evaluate({
    bool documentationReady = true,
    bool onboardingReady = true,
    bool demoReady = true,
  }) {
    const plans = {
      'Free': LaunchCheckStatus.ready,
      'Student': LaunchCheckStatus.ready,
      'Teacher': LaunchCheckStatus.ready,
      'Institution': LaunchCheckStatus.pending,
      'Enterprise': LaunchCheckStatus.pending,
    };
    const pricingReady = false;
    const landingReady = false;
    const supportReady = false;
    final signals = [
      pricingReady,
      landingReady,
      documentationReady,
      supportReady,
      onboardingReady,
      demoReady,
      ...plans.values.map((status) => status == LaunchCheckStatus.ready),
    ];
    final score =
        (signals.where((value) => value).length / signals.length * 100).round();
    return CommercialReadiness(
      score: score,
      plans: plans,
      pricingReady: pricingReady,
      landingReady: landingReady,
      documentationReady: documentationReady,
      supportReady: supportReady,
      onboardingReady: onboardingReady,
      demoReady: demoReady,
      pendingItems: const [
        'Validar pricing comercial.',
        'Publicar landing de lanzamiento.',
        'Definir canal y SLA de soporte.',
        'Cerrar planes Institution y Enterprise.',
      ],
    );
  }
}
