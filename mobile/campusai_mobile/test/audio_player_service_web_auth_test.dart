import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:campusai_mobile/services/audio_player_service.dart';

void main() {
  group('authenticated Web audio', () {
    test('fetches API audio with auth and returns a playable data URL',
        () async {
      Uri? requestedUri;
      Map<String, String>? requestedHeaders;

      final result = await prepareAudioPlaybackUrl(
        audioUrl: 'https://api.studybookai.com/audio/welcome.mp3',
        apiBaseUrl: 'https://api.studybookai.com',
        isWeb: true,
        requestHeaders: const {'Authorization': 'Bearer test-token'},
        responseLoader: (uri, headers) async {
          requestedUri = uri;
          requestedHeaders = headers;
          return http.Response.bytes(
            utf8.encode('synthetic-mp3'),
            200,
            headers: const {'content-type': 'audio/mpeg'},
          );
        },
      );

      expect(
        requestedUri,
        Uri.parse('https://api.studybookai.com/audio/welcome.mp3'),
      );
      expect(requestedHeaders?['Authorization'], 'Bearer test-token');
      expect(result, startsWith('data:audio/mpeg;base64,'));
    });

    test('does not fetch external or unauthenticated audio', () async {
      var requestCount = 0;

      Future<http.Response> loader(
        Uri uri,
        Map<String, String> headers,
      ) async {
        requestCount += 1;
        return http.Response('', 500);
      }

      final external = await prepareAudioPlaybackUrl(
        audioUrl: 'https://cdn.example.com/audio.mp3',
        apiBaseUrl: 'https://api.studybookai.com',
        isWeb: true,
        requestHeaders: const {'Authorization': 'Bearer test-token'},
        responseLoader: loader,
      );
      final signedOut = await prepareAudioPlaybackUrl(
        audioUrl: 'https://api.studybookai.com/audio/public.mp3',
        apiBaseUrl: 'https://api.studybookai.com',
        isWeb: true,
        requestHeaders: const {},
        responseLoader: loader,
      );

      expect(external, 'https://cdn.example.com/audio.mp3');
      expect(signedOut, 'https://api.studybookai.com/audio/public.mp3');
      expect(requestCount, 0);
    });

    test('reports an authorization failure without exposing response data',
        () async {
      expect(
        () => prepareAudioPlaybackUrl(
          audioUrl: 'https://api.studybookai.com/audio/welcome.mp3',
          apiBaseUrl: 'https://api.studybookai.com',
          isWeb: true,
          requestHeaders: const {'Authorization': 'Bearer test-token'},
          responseLoader: (uri, headers) async => http.Response('private', 401),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('no autorizó'),
          ),
        ),
      );
    });
  });
}
