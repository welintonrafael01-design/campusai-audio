import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_history.dart';
import '../services/history_service.dart';

final activeDocumentProvider =
    StateNotifierProvider<ActiveDocumentNotifier, DocumentHistory?>(
  (ref) => ActiveDocumentNotifier(),
);

class ActiveDocumentNotifier extends StateNotifier<DocumentHistory?> {
  ActiveDocumentNotifier() : super(null) {
    loadActiveDocument();
  }

  Future<void> loadActiveDocument() async {
    final document = await HistoryService.getActiveDocument();

    state = document;
  }

  Future<void> setDocument(
    DocumentHistory document,
  ) async {
    await HistoryService.saveActiveDocument(
      document,
    );

    state = document;
  }

  Future<void> clearDocument() async {
    await HistoryService.clearActiveDocument();

    state = null;
  }

  bool get hasDocument => state != null && state!.documentId.trim().isNotEmpty;
}

final activeWorkspaceProvider =
    StateNotifierProvider<ActiveWorkspaceNotifier, List<String>>(
  (ref) => ActiveWorkspaceNotifier(),
);

class ActiveWorkspaceNotifier extends StateNotifier<List<String>> {
  ActiveWorkspaceNotifier() : super([]);

  void setWorkspaceDocuments(
    List<String> documentIds,
  ) {
    state = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  void removeDocument(
    String documentId,
  ) {
    state = state.where((item) => item != documentId).toList();
  }

  void clearWorkspace() {
    state = [];
  }

  bool get hasWorkspace => state.length > 1;
}
