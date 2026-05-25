import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../section_card.dart';

class DashboardAudioSection extends StatelessWidget {
  final String fileName;
  final String fullAudioUrl;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;
  final ValueChanged<double> onSeek;

  const DashboardAudioSection({
    super.key,
    required this.fileName,
    required this.fullAudioUrl,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onReplay,
    required this.onSeek,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (fullAudioUrl.isEmpty) return const SizedBox.shrink();

    final maxSeconds =
        totalDuration.inSeconds > 0 ? totalDuration.inSeconds.toDouble() : 1.0;

    final currentSeconds =
        currentPosition.inSeconds.clamp(0, maxSeconds.toInt()).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardAudioTitle(
          title: 'Audio generado',
          subtitle: 'Escucha el resumen como audioclase.',
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName.isEmpty ? 'Audiolibro inteligente' : fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: currentSeconds,
                min: 0,
                max: maxSeconds,
                onChanged: onSeek,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(currentPosition),
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  Text(
                    _formatDuration(totalDuration),
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPlayPause,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        isPlaying ? 'Pausar audio' : 'Reproducir audio',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardAudioTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DashboardAudioTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
