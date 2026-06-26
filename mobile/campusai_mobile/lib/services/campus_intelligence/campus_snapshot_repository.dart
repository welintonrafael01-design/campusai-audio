import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'campus_intelligence_models.dart';

class CampusSnapshotRepository {
  static const String snapshotType = 'campus_intelligence_snapshot';
  static const String latestDocumentId = 'campus_intelligence_latest';

  const CampusSnapshotRepository();

  Future<void> saveSnapshot(CampusIntelligenceSnapshot snapshot) async {
    if (snapshot.generatedAt.millisecondsSinceEpoch <= 0) return;

    try {
      final previous = await getLatestSnapshot();
      final shouldCreateHistory = previous == null ||
          snapshot.generatedAt.difference(previous.generatedAt).inMinutes >= 5;

      await _save(
        documentId: latestDocumentId,
        snapshot: snapshot,
      );

      if (shouldCreateHistory) {
        await _save(
          documentId:
              'campus_intelligence_${snapshot.generatedAt.millisecondsSinceEpoch}',
          snapshot: snapshot,
        );
        await clearOldSnapshots();
      }
    } catch (error) {
      debugPrint('CampusSnapshotRepository.saveSnapshot: $error');
    }
  }

  Future<CampusIntelligenceSnapshot?> getLatestSnapshot() async {
    try {
      final result = await StudyResultService.getResult(
        documentId: latestDocumentId,
        type: snapshotType,
      );
      return _decodeSnapshot(result);
    } catch (error) {
      debugPrint('CampusSnapshotRepository.getLatestSnapshot: $error');
      return null;
    }
  }

  Future<List<CampusIntelligenceSnapshot>> getSnapshotHistory({
    int limit = 20,
  }) async {
    try {
      final results = await StudyResultService.getResultsByType(snapshotType);
      final snapshots = <CampusIntelligenceSnapshot>[];

      for (final result in results) {
        if (result.documentId == latestDocumentId) continue;
        final snapshot = _decodeSnapshot(result);
        if (snapshot != null) snapshots.add(snapshot);
      }

      snapshots.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return snapshots.take(limit < 1 ? 1 : limit).toList();
    } catch (error) {
      debugPrint('CampusSnapshotRepository.getSnapshotHistory: $error');
      return const [];
    }
  }

  Future<void> clearOldSnapshots({int keep = 50}) async {
    try {
      final results = await StudyResultService.getResultsByType(snapshotType);
      final history = results
          .where((result) => result.documentId != latestDocumentId)
          .toList();

      history.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      for (final result in history.skip(keep < 1 ? 1 : keep)) {
        await StudyResultService.deleteResult(
          documentId: result.documentId,
          type: snapshotType,
        );
      }
    } catch (error) {
      debugPrint('CampusSnapshotRepository.clearOldSnapshots: $error');
    }
  }

  Future<void> _save({
    required String documentId,
    required CampusIntelligenceSnapshot snapshot,
  }) async {
    await StudyResultService.saveResult(
      StudyResult(
        documentId: documentId,
        type: snapshotType,
        content: jsonEncode(snapshot.toJson()),
        createdAt: snapshot.generatedAt.toIso8601String(),
      ),
    );
  }

  CampusIntelligenceSnapshot? _decodeSnapshot(StudyResult? result) {
    if (result == null || result.content.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(result.content);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : null;
      if (map == null) return null;
      return CampusIntelligenceSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
