import 'dart:convert';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'launch_models.dart';

/// Local-first beta feedback without user identifiers or sensitive metadata.
class UserFeedbackService {
  static const feedbackType = 'beta_feedback';

  const UserFeedbackService();

  Future<BetaFeedback?> submit({
    required FeedbackCategory category,
    required String message,
    FeedbackPriority priority = FeedbackPriority.normal,
    String source = 'app',
  }) async {
    final cleanMessage = _clean(message, 2000);
    if (cleanMessage.isEmpty) return null;
    final now = DateTime.now();
    final feedback = BetaFeedback(
      id: 'beta_feedback_${now.microsecondsSinceEpoch}',
      category: category,
      priority: priority,
      status: FeedbackStatus.open,
      message: cleanMessage,
      source: _clean(source, 80),
      createdAt: now,
    );
    await _save(feedback);
    return feedback;
  }

  Future<List<BetaFeedback>> listFeedback() async {
    final results = await StudyResultService.getResultsByType(feedbackType);
    final feedback = <BetaFeedback>[];
    for (final result in results) {
      try {
        final decoded = jsonDecode(result.content);
        if (decoded is Map) {
          feedback
              .add(BetaFeedback.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    feedback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return feedback;
  }

  Future<void> markReviewed(String feedbackId) async {
    final existing = await StudyResultService.getResult(
      documentId: feedbackId,
      type: feedbackType,
    );
    if (existing == null) return;
    try {
      final decoded = jsonDecode(existing.content);
      if (decoded is! Map) return;
      final feedback = BetaFeedback.fromJson(
        Map<String, dynamic>.from(decoded),
      ).copyWith(status: FeedbackStatus.reviewed, reviewedAt: DateTime.now());
      await _save(feedback);
    } catch (_) {}
  }

  Future<FeedbackSummary> buildSummary() async {
    final items = await listFeedback();
    final byCategory = <String, int>{};
    for (final item in items) {
      byCategory.update(item.category.name, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return FeedbackSummary(
      total: items.length,
      open: items.where((item) => item.status == FeedbackStatus.open).length,
      reviewed:
          items.where((item) => item.status != FeedbackStatus.open).length,
      critical: items
          .where((item) => item.priority == FeedbackPriority.critical)
          .length,
      byCategory: byCategory,
    );
  }

  Future<void> _save(BetaFeedback feedback) => StudyResultService.saveResult(
        StudyResult(
          documentId: feedback.id,
          type: feedbackType,
          content: jsonEncode(feedback.toJson()),
          createdAt: feedback.createdAt.toIso8601String(),
        ),
      );

  String _clean(String value, int maxLength) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) return compact;
    return compact.substring(0, maxLength);
  }
}
