import 'local_storage_service.dart';
import 'plan_guard_service.dart';
import 'security/user_scoped_storage.dart';

class UsageLimitService {
  const UsageLimitService();

  static const String _pdfUploadDateKey = 'studybook_ai_pdf_upload_date';
  static const String _pdfUploadCountKey = 'studybook_ai_pdf_upload_count';
  String get _scopedUploadDateKey => UserScopedStorage.key(_pdfUploadDateKey);
  String get _scopedUploadCountKey => UserScopedStorage.key(_pdfUploadCountKey);

  String _monthKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  int getPdfUploadsThisMonth() {
    final month = _monthKey();
    final storedDate = LocalStorageService.getString(_scopedUploadDateKey);

    if (storedDate != month) {
      return 0;
    }

    final rawCount = LocalStorageService.getString(_scopedUploadCountKey);

    return int.tryParse(rawCount ?? '0') ?? 0;
  }

  int get maxPdfUploadsPerDay {
    return const PlanGuardService().limits.maxPdfUploadsPerDay;
  }

  int getPdfUploadsToday() => getPdfUploadsThisMonth();

  bool canUploadPdfToday() {
    return getPdfUploadsThisMonth() < maxPdfUploadsPerDay;
  }

  void registerPdfUpload() {
    final month = _monthKey();
    final storedDate = LocalStorageService.getString(_scopedUploadDateKey);

    if (storedDate != month) {
      LocalStorageService.setString(_scopedUploadDateKey, month);
      LocalStorageService.setString(_scopedUploadCountKey, '1');
      return;
    }

    final currentCount = getPdfUploadsThisMonth();

    LocalStorageService.setString(
      _scopedUploadCountKey,
      '${currentCount + 1}',
    );
  }

  String pdfUploadLimitMessage() {
    return 'Has utilizado tus $maxPdfUploadsPerDay usos gratuitos de este mes.';
  }

  void resetPdfUploadsToday() {
    LocalStorageService.remove(_scopedUploadDateKey);
    LocalStorageService.remove(_scopedUploadCountKey);
  }
}
