import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class CloudApiService {
  static Future<Map<String, dynamic>>
      createWorkspace({
    required String name,
    String description = '',
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces',
      ),
      headers: {
        'Content-Type': 'application/json',
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

  static Future<List<dynamic>>
      getWorkspaces() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/workspaces',
      ),
    );

    final data =
        ApiService.decodeResponse(response);

    return data['workspaces'] ?? [];
  }

  static Future<Map<String, dynamic>>
      createDocument({
    required String workspaceId,
    required String documentName,
    required String documentId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/documents',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'workspace_id': workspaceId,
        'document_name': documentName,
        'document_id': documentId,
      }),
    );

    return ApiService.decodeResponse(
      response,
    );
  }

  static Future<List<dynamic>>
      getDocuments({
    String? workspaceId,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/cloud/documents',
    ).replace(
      queryParameters:
          workspaceId == null
              ? {}
              : {
                  'workspace_id':
                      workspaceId,
                },
    );

    final response = await http.get(uri);

    final data =
        ApiService.decodeResponse(response);

    return data['documents'] ?? [];
  }


  static Future<Map<String, dynamic>>
      createChat({
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

  static Future<Map<String, dynamic>>
      saveMessage({
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

  static Future<List<dynamic>>
      getMessages({
    required String chatId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/messages/$chatId',
      ),
    );

    final data =
        ApiService.decodeResponse(response);

    return data['messages'] ?? [];
  }



  static Future<List<dynamic>> getChats() async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cloud/chats',
      ),
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
      },
      body: jsonEncode({
        'title': title,
      }),
    );

    return ApiService.decodeResponse(response);
  }

}
