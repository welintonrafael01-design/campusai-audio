import 'dart:html' as html;

import 'plan_guard_service.dart';

class UsageLimitService {
  const UsageLimitService();

  static const String _pdfUploadDateKey = 'studybook_ai_pdf_upload_date';
  static const String _pdfUploadCountKey = 'studybook_ai_pdf_upload_count';

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  int getPdfUploadsToday() {
    final today = _todayKey();
    final storedDate = html.window.localStorage[_pdfUploadDateKey];

    if (storedDate != today) {
      return 0;
    }

    final rawCount = html.window.localStorage[_pdfUploadCountKey];

    return int.tryParse(rawCount ?? '0') ?? 0;
  }

  int get maxPdfUploadsPerDay {
    return const PlanGuardService().limits.maxPdfUploadsPerDay;
  }

  bool canUploadPdfToday() {
    return getPdfUploadsToday() < maxPdfUploadsPerDay;
  }

  void registerPdfUpload() {
    final today = _todayKey();
    final storedDate = html.window.localStorage[_pdfUploadDateKey];

    if (storedDate != today) {
      html.window.localStorage[_pdfUploadDateKey] = today;
      html.window.localStorage[_pdfUploadCountKey] = '1';
      return;
    }

    final currentCount = getPdfUploadsToday();
    html.window.localStorage[_pdfUploadCountKey] = '${currentCount + 1}';
  }

  String pdfUploadLimitMessage() {
    return 'Tu plan actual permite $maxPdfUploadsPerDay PDFs por día. Ya alcanzaste el límite de hoy.';
  }

  void resetPdfUploadsToday() {
    html.window.localStorage.remove(_pdfUploadDateKey);
    html.window.localStorage.remove(_pdfUploadCountKey);
  }
}
