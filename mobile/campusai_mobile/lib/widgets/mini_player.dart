import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    if (audioState.audioUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSeconds =
        audioState.duration.inSeconds > 0 ? audioState.duration.inSeconds : 1;

    final currentSeconds = audioState.position.inSeconds.clamp(0, totalSeconds);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: currentSeconds.toDouble(),
            min: 0,
            max: totalSeconds.toDouble(),
            onChanged: (value) {
              audioNotifier.seek(
                Duration(seconds: value.toInt()),
              );
            },
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  audioState.title.isEmpty
                      ? 'Audio IA'
                      : audioState.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${formatDuration(audioState.position)} / ${formatDuration(audioState.duration)}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: audioState.isPlaying
                    ? audioNotifier.pause
                    : () => audioNotifier.play(
                          audioUrl: audioState.audioUrl,
                          title: audioState.title,
                        ),
                icon: Icon(
                  audioState.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}