import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';
import '../../services/launch/onboarding_readiness_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';

class StudyBookOnboardingDialog extends ConsumerStatefulWidget {
  const StudyBookOnboardingDialog({super.key});

  @override
  ConsumerState<StudyBookOnboardingDialog> createState() =>
      _StudyBookOnboardingDialogState();
}

class _StudyBookOnboardingDialogState
    extends ConsumerState<StudyBookOnboardingDialog> {
  bool isGeneratingWelcomeAudio = false;

  String get welcomeText {
    return '''
Hola, soy Booky, tu compañero de aprendizaje en StudyBook AI. Te ayudo a transformar cualquier contenido en conocimiento.

Sube o pega cualquier contenido. Puedo convertirlo en AudioBook, resumen, flashcards y quiz, y acompañarte cuando necesites una explicación.

Empecemos por algo sencillo. Puedes crear tu primera experiencia en menos de dos minutos.
''';
  }

  Future<void> complete(BuildContext context) async {
    await const OnboardingService().markCompleted();

    if (!context.mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> skip(BuildContext context) async {
    await const OnboardingReadinessService().skip();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> playWelcomeAudio() async {
    if (isGeneratingWelcomeAudio) return;

    setState(() {
      isGeneratingWelcomeAudio = true;
    });

    try {
      final data = await ApiService.generateAudioFromText(
        text: welcomeText,
      );

      final audioUrl = data['audio_url']?.toString() ?? '';

      if (audioUrl.trim().isEmpty) {
        throw Exception('No se recibió audio de bienvenida.');
      }

      final fullAudioUrl = ApiService.buildAudioUrl(audioUrl);

      await ref.read(audioProvider.notifier).play(
            audioUrl: fullAudioUrl,
            title: 'Bienvenida a StudyBook AI',
          );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booky no pudo reproducir la bienvenida esta vez.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingWelcomeAudio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      titlePadding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
      contentPadding: const EdgeInsets.fromLTRB(26, 18, 26, 10),
      actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: AppTheme.mainGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Booky te da la bienvenida',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 21,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hola, soy Booky. Te ayudaré a transformar contenido en conocimiento.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isGeneratingWelcomeAudio ? null : playWelcomeAudio,
                  icon: isGeneratingWelcomeAudio
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Icon(Icons.volume_up_rounded),
                  label: Text(
                    isGeneratingWelcomeAudio
                        ? 'Generando bienvenida...'
                        : 'Escuchar bienvenida',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _OnboardingStep(
                icon: Icons.upload_file_rounded,
                title: '1. Sube o pega contenido',
                subtitle: 'Usa un texto, documento, libro o material de clase.',
              ),
              _OnboardingStep(
                icon: Icons.auto_stories_rounded,
                title: '2. Booky lo transforma',
                subtitle:
                    'Obtén audio, resumen, flashcards y práctica en minutos.',
              ),
              _OnboardingStep(
                icon: Icons.headphones_rounded,
                title: '3. Aprende como prefieras',
                subtitle:
                    'Escucha, lee, practica o pregunta a Booky paso a paso.',
              ),
              const _OnboardingStep(
                icon: Icons.accessibility_new_rounded,
                title: 'Aprende a tu manera',
                subtitle:
                    'Ajusta audio, texto grande, lenguaje simple y contraste cuando quieras.',
              ),
              const _OnboardingStep(
                icon: Icons.school_outlined,
                title: '¿Eres docente?',
                subtitle:
                    'Crea tu primer curso y genera recursos desde Teacher Studio.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => skip(context),
          child: const Text('Saltar por ahora'),
        ),
        FilledButton.icon(
          onPressed: () => complete(context),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Empezar con Booky'),
        ),
      ],
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
