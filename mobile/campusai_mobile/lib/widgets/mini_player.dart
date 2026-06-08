import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    if (audioState.audioUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSeconds =
        audioState.duration.inSeconds > 0 ? audioState.duration.inSeconds : 1;

    final currentSeconds = audioState.position.inSeconds.clamp(
      0,
      totalSeconds,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                  audioState.title.isEmpty ? l10n.aiAudio : audioState.title,
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
              const SizedBox(width: 6),
              IconButton(
                tooltip: l10n.close,
                onPressed: audioNotifier.stop,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '-10s',
                onPressed: () => audioNotifier.skipBackward(seconds: 10),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                height: 54,
                child: FilledButton(
                  onPressed: () async {
                    if (audioState.isPlaying) {
                      await audioNotifier.pause();
                      return;
                    }

                    await audioNotifier.play(
                      audioUrl: audioState.audioUrl,
                      title: audioState.title,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Icon(
                    audioState.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '+10s',
                onPressed: () => audioNotifier.skipForward(seconds: 10),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.restart,
                onPressed: audioNotifier.replay,
                icon: const Icon(Icons.replay_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
