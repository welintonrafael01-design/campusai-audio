import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class CloudApiService {
  static Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String description = '',
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    return ApiService.decodeResponse(
      response,
    );
  }

  static Future<List<dynamic>> getWorkspaces() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['workspaces'] ?? [];
  }

  static Future<Map<String, dynamic>> createDocument({
    required String workspaceId,
    required String documentName,
    required String documentId,
    String summary = '',
    String audioUrl = '',
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/documents',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'workspace_id': workspaceId,
        'document_name': documentName,
        'document_id': documentId,
        'summary': summary,
        'audio_url': audioUrl,
      }),
    );

    return ApiService.decodeResponse(
      response,
    );
  }

  static Future<List<dynamic>> getDocuments({
    String? workspaceId,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/cloud/documents',
    ).replace(
      queryParameters: workspaceId == null
          ? {}
          : {
              'workspace_id': workspaceId,
            },
    );

    final response = await http.get(
      uri,
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['documents'] ?? [];
  }

  static Future<Map<String, dynamic>> rehydrateDocument({
    required String documentId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/rehydrate-document/$documentId',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }

  static Future<String> getDocumentDownloadUrl({
    required String documentId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/document-download-url/$documentId',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    final url = data['signed_url']?.toString() ?? '';

    if (url.trim().isEmpty) {
      throw Exception('El servidor no devolvió una URL de descarga.');
    }

    return url;
  }

  static Future<List<dynamic>> getLibraryDocuments() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/library-documents',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['documents'] ?? [];
  }

  static Future<Map<String, dynamic>> createChat({
    String? workspaceId,
    String? documentId,
    String title = 'Nuevo chat',
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/chats',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        if (workspaceId != null && workspaceId.isNotEmpty)
          'workspace_id': workspaceId,
        if (documentId != null && documentId.isNotEmpty)
          'document_id': documentId,
        'title': title,
      }),
    );

    return ApiService.decodeResponse(
      response,
    );
  }

  static Future<Map<String, dynamic>> saveMessage({
    required String chatId,
    required String role,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/messages',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'chat_id': chatId,
        'role': role,
        'content': content,
      }),
    );

    return ApiService.decodeResponse(
      response,
    );
  }

  static Future<List<dynamic>> getMessages({
    required String chatId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/messages/$chatId',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['messages'] ?? [];
  }

  static Future<List<dynamic>> getChats({
    String? workspaceId,
    String? documentId,
  }) async {
    final queryParameters = <String, String>{};

    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      queryParameters['workspace_id'] = workspaceId.trim();
    }

    if (documentId != null && documentId.trim().isNotEmpty) {
      queryParameters['document_id'] = documentId.trim();
    }

    final uri = Uri.parse(
      '${ApiService.baseUrl}/cloud/chats',
    ).replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['chats'] ?? [];
  }

  static Future<List<dynamic>> getChatMessages({
    required String chatId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/chats/$chatId/messages',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['messages'] ?? [];
  }

  static Future<Map<String, dynamic>> deleteChat({
    required String chatId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/chats/$chatId',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateChatTitle({
    required String chatId,
    required String title,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/chats/$chatId',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'title': title,
      }),
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> saveStudyResult({
    required String documentId,
    required String type,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${ApiService.baseUrl}/cloud/study-results',
          ),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'document_id': documentId,
            'type': type,
            'content': content,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>?> getStudyResult({
    required String documentId,
    required String type,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiService.baseUrl}/cloud/study-results/$documentId/$type',
          ),
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    final data = ApiService.decodeResponse(response);

    return data['study_result'];
  }

  static Future<List<dynamic>> getStudyResults({
    String? type,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/cloud/study-results',
    ).replace(
      queryParameters: type == null
          ? {}
          : {
              'type': type,
            },
    );

    final response = await http
        .get(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    final data = ApiService.decodeResponse(response);

    return data['study_results'] ?? [];
  }

  static Future<Map<String, dynamic>> saveAudiobook({
    required String documentId,
    required String fileName,
    required List<Map<String, dynamic>> chapters,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/audiobooks',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'document_id': documentId,
        'file_name': fileName,
        'chapters': chapters,
      }),
    );

    return ApiService.decodeResponse(response);
  }

  static Future<List<dynamic>> getAudiobooks() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/audiobooks',
      ),
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    return data['audiobooks'] ?? [];
  }

  static Future<Map<String, dynamic>> deleteAudiobook({
    required String documentId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/audiobooks/$documentId',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> deleteStudyResult({
    required String documentId,
    required String type,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/study-results/$documentId/$type',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> deleteDocument({
    required String documentId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/documents/$documentId',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> updateWorkspace({
    required String workspaceId,
    required String name,
    String description = '',
  }) async {
    final response = await http.patch(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces/$workspaceId',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    return ApiService.decodeResponse(response);
  }

  static Future<Map<String, dynamic>> deleteWorkspace({
    required String workspaceId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces/$workspaceId',
      ),
      headers: AuthService.authHeaders,
    );

    return ApiService.decodeResponse(response);
  }
}
