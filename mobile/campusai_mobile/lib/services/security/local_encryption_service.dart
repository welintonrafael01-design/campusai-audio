import 'dart:convert';

class LocalEncryptionService {
  const LocalEncryptionService();
  String protect(String value) => base64Encode(utf8.encode(value));
  String unprotect(String value) {
    try {
      return utf8.decode(base64Decode(value));
    } catch (_) {
      return '';
    }
  }
}
