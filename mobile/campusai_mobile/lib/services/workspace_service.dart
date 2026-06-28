import 'dart:convert';

import '../models/workspace_model.dart';
import 'security/user_scoped_storage.dart';

class WorkspaceService {
  static const String _key = 'ai_workspaces';
  static const int _maxWorkspaces = 20;

  static Future<List<WorkspaceModel>> getWorkspaces() async {
    final raw = await UserScopedStorage.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map(
            (item) => WorkspaceModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .where((item) => item.workspaceId.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveWorkspace(
    WorkspaceModel workspace,
  ) async {
    final current = await getWorkspaces();

    final updated = [
      workspace,
      ...current.where(
        (item) => item.workspaceId != workspace.workspaceId,
      ),
    ].take(_maxWorkspaces).toList();

    await UserScopedStorage.setString(
      _key,
      jsonEncode(
        updated.map((item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<void> updateWorkspace(
    WorkspaceModel workspace,
  ) async {
    await saveWorkspace(workspace);
  }

  static Future<void> removeWorkspace(
    String workspaceId,
  ) async {
    final current = await getWorkspaces();

    final updated =
        current.where((item) => item.workspaceId != workspaceId).toList();

    await UserScopedStorage.setString(
      _key,
      jsonEncode(
        updated.map((item) => item.toJson()).toList(),
      ),
    );
  }

  static Future<void> clearWorkspaces() async {
    await UserScopedStorage.remove(_key);
  }
}
