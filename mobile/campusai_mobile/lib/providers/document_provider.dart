import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_history.dart';
import '../services/history_service.dart';

final activeDocumentProvider =
    StateNotifierProvider<
      ActiveDocumentNotifier,
      DocumentHistory?
    >(
  (ref) => ActiveDocumentNotifier(),
);

class ActiveDocumentNotifier
    extends StateNotifier<DocumentHistory?> {
  ActiveDocumentNotifier() : super(null) {
    loadActiveDocument();
  }

  Future<void> loadActiveDocument() async {
    final document =
        await HistoryService.getActiveDocument();

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

  bool get hasDocument =>
      state != null &&
      state!.documentId.trim().isNotEmpty;
}