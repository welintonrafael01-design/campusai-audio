import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();

  String? _currentUrl;
  double _currentSpeed = 1.0;

  Stream<Duration?> get durationStream => player.durationStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      player.processingStateStream;

  bool get isPlaying => player.playing;
  bool get hasAudioLoaded => _currentUrl != null;
  double get currentSpeed => _currentSpeed;
  Duration get currentPosition => player.position;
  Duration? get totalDuration => player.duration;

  Future<void> play(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      throw Exception('URL de audio inválida.');
    }

    try {
      if (_currentUrl != cleanUrl) {
        _currentUrl = cleanUrl;

        await player.stop();

        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(cleanUrl),
          ),
        );

        await player.setSpeed(_currentSpeed);
      }

      unawaited(player.play());
    } catch (error) {
      _currentUrl = null;

      throw Exception(
        'No se pudo reproducir el audio: $error',
      );
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> preload(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) return;

    if (_currentUrl == cleanUrl) {
      return;
    }

    _currentUrl = cleanUrl;

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(cleanUrl),
      ),
    );

    await player.setSpeed(_currentSpeed);
  }

  Future<void> stop() async {
    await player.stop();
    await player.seek(Duration.zero);
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    if (speed <= 0) return;

    _currentSpeed = speed;
    await player.setSpeed(speed);
  }

  Future<void> replay() async {
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  Future<void> skipForward({
    int seconds = 10,
  }) async {
    final duration = player.duration;
    final current = player.position;
    final target = current + Duration(seconds: seconds);

    if (duration != null && target > duration) {
      await seek(duration);
      return;
    }

    await seek(target);
  }

  Future<void> skipBackward({
    int seconds = 10,
  }) async {
    final current = player.position;
    final target = current - Duration(seconds: seconds);

    if (target.isNegative) {
      await seek(Duration.zero);
      return;
    }

    await seek(target);
  }

  Future<void> reset() async {
    await stop();

    _currentUrl = null;
    _currentSpeed = 1.0;
  }

  void dispose() {
    player.dispose();
  }
}
