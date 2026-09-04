import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../config/app_environment.dart';
import 'auth_service.dart';

typedef AudioResponseLoader = Future<http.Response> Function(
  Uri uri,
  Map<String, String> headers,
);

bool shouldFetchAuthenticatedAudio({
  required bool isWeb,
  required String audioUrl,
  required String apiBaseUrl,
  required bool isAuthenticated,
}) {
  if (!isWeb || !isAuthenticated) return false;

  final audioUri = Uri.tryParse(audioUrl);
  final apiUri = Uri.tryParse(apiBaseUrl);
  if (audioUri == null || apiUri == null || !audioUri.hasScheme) return false;

  return audioUri.origin == apiUri.origin;
}

Future<String> prepareAudioPlaybackUrl({
  required String audioUrl,
  required String apiBaseUrl,
  required bool isWeb,
  required Map<String, String> requestHeaders,
  AudioResponseLoader? responseLoader,
}) async {
  if (!shouldFetchAuthenticatedAudio(
    isWeb: isWeb,
    audioUrl: audioUrl,
    apiBaseUrl: apiBaseUrl,
    isAuthenticated: requestHeaders.isNotEmpty,
  )) {
    return audioUrl;
  }

  final loader = responseLoader ??
      (Uri uri, Map<String, String> headers) => http.get(uri, headers: headers);
  final response = await loader(Uri.parse(audioUrl), requestHeaders);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('El servidor no autorizó la reproducción del audio.');
  }

  final mimeType =
      response.headers['content-type']?.split(';').first.trim() ?? 'audio/mpeg';

  return Uri.dataFromBytes(
    response.bodyBytes,
    mimeType: mimeType.isEmpty ? 'audio/mpeg' : mimeType,
  ).toString();
}

bool shouldRestartAudioPlayback({
  required String? currentUrl,
  required String requestedUrl,
  required bool isCompleted,
  required Duration position,
  required Duration? duration,
}) {
  if (currentUrl != requestedUrl) return false;
  if (isCompleted) return true;
  return duration != null && duration > Duration.zero && position >= duration;
}

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

  Map<String, String>? get _requestHeaders =>
      AuthService.isLoggedIn ? AuthService.authHeaders : null;

  Future<void> play(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      throw Exception('URL de audio inválida.');
    }

    try {
      if (_currentUrl != cleanUrl) {
        _currentUrl = cleanUrl;

        await player.stop();

        final requestHeaders = _requestHeaders ?? const <String, String>{};
        final playbackUrl = await prepareAudioPlaybackUrl(
          audioUrl: cleanUrl,
          apiBaseUrl: AppEnvironment.apiBaseUrl,
          isWeb: kIsWeb,
          requestHeaders: requestHeaders,
        );

        await player.setUrl(
          playbackUrl,
          headers: kIsWeb ? null : _requestHeaders,
        );

        await player.setSpeed(_currentSpeed);
      } else if (shouldRestartAudioPlayback(
        currentUrl: _currentUrl,
        requestedUrl: cleanUrl,
        isCompleted: player.processingState == ProcessingState.completed,
        position: player.position,
        duration: player.duration,
      )) {
        await player.seek(Duration.zero);
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

    final requestHeaders = _requestHeaders ?? const <String, String>{};
    final playbackUrl = await prepareAudioPlaybackUrl(
      audioUrl: cleanUrl,
      apiBaseUrl: AppEnvironment.apiBaseUrl,
      isWeb: kIsWeb,
      requestHeaders: requestHeaders,
    );

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(playbackUrl),
        headers: kIsWeb ? null : _requestHeaders,
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
