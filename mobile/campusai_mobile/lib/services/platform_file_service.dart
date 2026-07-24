import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PlatformFileService {
  PlatformFileService._();

  static Future<bool> saveTextFile({
    required String filename,
    required String content,
    String dialogTitle = 'Guardar archivo',
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [_extensionOf(filename)],
      bytes: bytes,
    );

    return outputPath != null;
  }

  static Future<bool> saveBinaryFile({
    required String filename,
    required List<int> bytes,
    String dialogTitle = 'Guardar archivo',
  }) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [_extensionOf(filename)],
      bytes: Uint8List.fromList(bytes),
    );

    return outputPath != null;
  }

  static Future<String?> pickTextFile({
    List<String> allowedExtensions = const ['csv'],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final bytes = result.files.single.bytes;

    if (bytes == null) {
      throw StateError(
        'No se pudo leer el contenido del archivo seleccionado.',
      );
    }

    return utf8.decode(
      bytes,
      allowMalformed: true,
    );
  }

  static String _extensionOf(String filename) {
    final separatorIndex = filename.lastIndexOf('.');

    if (separatorIndex < 0 || separatorIndex == filename.length - 1) {
      return 'txt';
    }

    return filename.substring(separatorIndex + 1).toLowerCase();
  }
}
