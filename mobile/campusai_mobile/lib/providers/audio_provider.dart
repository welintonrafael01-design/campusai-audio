import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_player_service.dart';

final audioProvider =
    StateNotifierProvider<AudioNotifier, AudioState>(
  (ref) => AudioNotifier(),
);

class AudioState {
  final bool isPlaying;
  final String audioUrl;
  final String title;
  final Duration position;
  final Duration duration;

  const AudioState({
    this.isPlaying = false,
    this.audioUrl = '',
    this.title = '',
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  AudioState copyWith({
    bool? isPlaying,
    String? audioUrl,
    String? title,
    Duration? position,
    Duration? duration,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      audioUrl: audioUrl ?? this.audioUrl,
      title: title ?? this.title,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  final AudioPlayerService _audioService = AudioPlayerService();

  AudioNotifier() : super(const AudioState()) {
    _audioService.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioService.durationStream.listen((duration) {
      state = state.copyWith(
        duration: duration ?? Duration.zero,
      );
    });
  }

  Future<void> play({
    required String audioUrl,
    required String title,
  }) async {
    if (audioUrl.trim().isEmpty) return;

    await _audioService.play(audioUrl);

    state = state.copyWith(
      audioUrl: audioUrl,
      title: title,
      isPlaying: true,
    );
  }

  Future<void> pause() async {
    await _audioService.pause();

    state = state.copyWith(
      isPlaying: false,
    );
  }

  Future<void> replay() async {
    await _audioService.replay();

    state = state.copyWith(
      isPlaying: true,
    );
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> stop() async {
    await _audioService.stop();

    state = state.copyWith(
      isPlaying: false,
      position: Duration.zero,
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}