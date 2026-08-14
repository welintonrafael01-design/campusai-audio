import 'dart:async';

import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';

typedef PdfPicker = Future<PlatformFile> Function();
typedef PdfUploader = Future<Map<String, dynamic>> Function(PlatformFile file);
typedef UploadStatusListener = void Function(
  DocumentUploadStatus status,
  String message,
);

enum DocumentUploadStatus {
  idle,
  picking,
  selected,
  uploading,
  processing,
  success,
  cancelled,
  unsupported,
  networkError,
  authError,
  serverError,
  processingError,
}

class DocumentUploadResult {
  const DocumentUploadResult({
    required this.status,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  final DocumentUploadStatus status;
  final String message;
  final Map<String, dynamic> data;

  bool get isSuccess => status == DocumentUploadStatus.success;
  bool get isCancelled => status == DocumentUploadStatus.cancelled;
  bool get canRetry =>
      status == DocumentUploadStatus.networkError ||
      status == DocumentUploadStatus.serverError ||
      status == DocumentUploadStatus.processingError;
}

class DocumentUploadController {
  DocumentUploadController({
    PdfPicker? picker,
    PdfUploader? uploader,
  })  : _picker = picker ?? ApiService.pickPdfFile,
        _uploader = uploader ?? ApiService.uploadPdfFile;

  final PdfPicker _picker;
  final PdfUploader _uploader;

  PlatformFile? _lastSelectedFile;

  Future<DocumentUploadResult> pickAndUploadPdf({
    UploadStatusListener? onStatusChanged,
  }) async {
    _notify(
      onStatusChanged,
      DocumentUploadStatus.picking,
      'Selecciona un PDF para empezar.',
    );

    final PlatformFile file;

    try {
      file = await _picker();
    } catch (error) {
      return _classifyPickError(error);
    }

    _lastSelectedFile = file;

    return uploadSelectedPdf(
      file,
      onStatusChanged: onStatusChanged,
    );
  }

  Future<DocumentUploadResult> retryLastUpload({
    UploadStatusListener? onStatusChanged,
  }) async {
    final file = _lastSelectedFile;

    if (file == null) {
      return const DocumentUploadResult(
        status: DocumentUploadStatus.cancelled,
        message: 'No hay un PDF seleccionado para reintentar.',
      );
    }

    return uploadSelectedPdf(
      file,
      onStatusChanged: onStatusChanged,
    );
  }

  Future<DocumentUploadResult> uploadSelectedPdf(
    PlatformFile file, {
    UploadStatusListener? onStatusChanged,
  }) async {
    _notify(
      onStatusChanged,
      DocumentUploadStatus.selected,
      'PDF seleccionado: ${file.name}',
    );
    _notify(
      onStatusChanged,
      DocumentUploadStatus.uploading,
      'Subiendo documento...',
    );
    _notify(
      onStatusChanged,
      DocumentUploadStatus.processing,
      'Procesando contenido...',
    );

    try {
      final data = await _uploader(file);

      _notify(
        onStatusChanged,
        DocumentUploadStatus.success,
        'Preparando herramientas AI...',
      );

      return DocumentUploadResult(
        status: DocumentUploadStatus.success,
        message: 'Documento listo.',
        data: data,
      );
    } catch (error) {
      return _classifyUploadError(error);
    }
  }

  DocumentUploadResult _classifyPickError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('no se seleccionó')) {
      return const DocumentUploadResult(
        status: DocumentUploadStatus.cancelled,
        message: 'Selección cancelada.',
      );
    }

    return DocumentUploadResult(
      status: DocumentUploadStatus.unsupported,
      message: _friendlyMessage(error),
    );
  }

  DocumentUploadResult _classifyUploadError(Object error) {
    final message = error.toString().toLowerCase();

    if (error is TimeoutException || message.contains('clientexception')) {
      return DocumentUploadResult(
        status: DocumentUploadStatus.networkError,
        message: _friendlyMessage(error),
      );
    }

    if (message.contains('iniciar sesión') ||
        message.contains('authorization') ||
        message.contains('401')) {
      return DocumentUploadResult(
        status: DocumentUploadStatus.authError,
        message: _friendlyMessage(error),
      );
    }

    if (message.contains('servidor') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503')) {
      return DocumentUploadResult(
        status: DocumentUploadStatus.serverError,
        message: _friendlyMessage(error),
      );
    }

    return DocumentUploadResult(
      status: DocumentUploadStatus.processingError,
      message: _friendlyMessage(error),
    );
  }

  String _friendlyMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    if (raw.isEmpty) {
      return 'No se pudo procesar el documento.';
    }

    return raw;
  }

  void _notify(
    UploadStatusListener? listener,
    DocumentUploadStatus status,
    String message,
  ) {
    listener?.call(status, message);
  }
}
