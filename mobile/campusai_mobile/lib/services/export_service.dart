import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import 'api_service.dart';

class ExportService {
  static Future<void> exportTextToPdf({
    required String title,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/export/pdf'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    ).timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'No se pudo exportar PDF: ${response.body}',
      );
    }

    final blob = html.Blob(
      [response.bodyBytes],
      'application/pdf',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
  ..setAttribute(
    'download',
    '${_safeFileName(title)}.pdf',
  )
  ..click();
        html.Url.revokeObjectUrl(url);
  }


  static Future<void> exportTextToDocx({
    required String title,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/export/docx'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
      }),
    ).timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'No se pudo exportar DOCX: ${response.body}',
      );
    }

    final blob = html.Blob(
      [response.bodyBytes],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        '${_safeFileName(title)}.docx',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  static String _safeFileName(String title) {
    final clean = title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');

    if (clean.isEmpty) {
      return 'studybook_export';
    }

    return clean.length > 80
        ? clean.substring(0, 80)
        : clean;
  }
}
