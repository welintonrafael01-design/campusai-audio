import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_player_service.dart';

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>(
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

    _audioService.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
      );
    });
  }

  Future<void> play({
    required String audioUrl,
    required String title,
  }) async {
    final cleanAudioUrl = audioUrl.trim();

    if (cleanAudioUrl.isEmpty) return;

    state = state.copyWith(
      audioUrl: cleanAudioUrl,
      title: title,
      isPlaying: true,
    );

    try {
      await _audioService.play(cleanAudioUrl);

      state = state.copyWith(
        audioUrl: cleanAudioUrl,
        title: title,
        isPlaying: true,
      );
    } catch (_) {
      state = state.copyWith(
        isPlaying: false,
      );

      rethrow;
    }
  }

  Future<void> pause() async {
    state = state.copyWith(
      isPlaying: false,
    );

    await _audioService.pause();

    state = state.copyWith(
      isPlaying: false,
    );
  }

  Future<void> replay() async {
    state = state.copyWith(
      isPlaying: true,
      position: Duration.zero,
    );

    await _audioService.replay();

    state = state.copyWith(
      isPlaying: true,
    );
  }

  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);

    await _audioService.seek(position);
  }

  Future<void> skipForward({
    int seconds = 10,
  }) async {
    await _audioService.skipForward(seconds: seconds);

    state = state.copyWith(
      position: _audioService.currentPosition,
    );
  }

  Future<void> skipBackward({
    int seconds = 10,
  }) async {
    await _audioService.skipBackward(seconds: seconds);

    state = state.copyWith(
      position: _audioService.currentPosition,
    );
  }

  Future<void> stop() async {
    await _audioService.stop();

    state = const AudioState();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
