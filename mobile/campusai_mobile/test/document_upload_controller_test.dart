import 'dart:async';
import 'dart:typed_data';

import 'package:campusai_mobile/controllers/document_upload_controller.dart';
import 'package:campusai_mobile/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PlatformFile pdfFile() {
    return PlatformFile(
      name: 'clase.pdf',
      size: 4,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
    );
  }

  test('cancelled picker returns idle-safe cancelled result', () async {
    final controller = DocumentUploadController(
      picker: () async => throw Exception('No se seleccionó archivo.'),
      uploader: (_) async => <String, dynamic>{},
    );

    final result = await controller.pickAndUploadPdf();

    expect(result.status, DocumentUploadStatus.cancelled);
    expect(result.isCancelled, isTrue);
    expect(result.canRetry, isFalse);
  });

  test('successful upload emits selected uploading processing success',
      () async {
    final statuses = <DocumentUploadStatus>[];
    final controller = DocumentUploadController(
      picker: () async => pdfFile(),
      uploader: (_) async => {
        'document_id': 'doc_1',
        'file_name': 'clase.pdf',
        'ai_summary': 'Resumen',
      },
    );

    final result = await controller.pickAndUploadPdf(
      onStatusChanged: (status, _) => statuses.add(status),
    );

    expect(result.isSuccess, isTrue);
    expect(result.data['document_id'], 'doc_1');
    expect(
      statuses,
      containsAllInOrder([
        DocumentUploadStatus.picking,
        DocumentUploadStatus.selected,
        DocumentUploadStatus.uploading,
        DocumentUploadStatus.processing,
        DocumentUploadStatus.success,
      ]),
    );
  });

  test('server errors are retryable', () async {
    final controller = DocumentUploadController(
      picker: () async => pdfFile(),
      uploader: (_) async => throw Exception('Error del servidor: 500'),
    );

    final result = await controller.pickAndUploadPdf();

    expect(result.status, DocumentUploadStatus.serverError);
    expect(result.canRetry, isTrue);
  });

  test('timeouts are network errors and retryable', () async {
    final controller = DocumentUploadController(
      picker: () async => pdfFile(),
      uploader: (_) async => throw TimeoutException('timeout'),
    );

    final result = await controller.pickAndUploadPdf();

    expect(result.status, DocumentUploadStatus.networkError);
    expect(result.canRetry, isTrue);
  });

  test('monthly quota denial preserves human message and upgrade action',
      () async {
    final controller = DocumentUploadController(
      picker: () async => pdfFile(),
      uploader: (_) async => throw const ApiEntitlementException(
        message: 'Has utilizado tus 3 usos gratuitos de este mes.',
        code: 'monthly_quota_exceeded',
        requiredPlan: 'student_pro',
        ctaLabel: 'Ver Student Pro',
      ),
    );

    final result = await controller.pickAndUploadPdf();

    expect(result.message, 'Has utilizado tus 3 usos gratuitos de este mes.');
    expect(result.upgradeActionLabel, 'Ver Student Pro');
    expect(result.hasUpgradeAction, isTrue);
    expect(result.canRetry, isFalse);
  });
}
