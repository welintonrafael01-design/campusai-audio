import 'package:campusai_mobile/utils/safe_external_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external URL policy allows HTTPS and rejects executable schemes', () {
    expect(isSafeExternalUri(Uri.parse('https://example.test/file')), isTrue);
    expect(isSafeExternalUri(Uri.parse('javascript:alert(1)')), isFalse);
    expect(isSafeExternalUri(Uri.parse('file:///private/data.pdf')), isFalse);
    expect(isSafeExternalUri(Uri.parse('intent://open')), isFalse);
  });

  test('HTTP is limited to explicit loopback development access', () {
    expect(isSafeExternalUri(Uri.parse('http://example.test/file')), isFalse);
    expect(
      isSafeExternalUri(
        Uri.parse('http://127.0.0.1:8000/documents/file'),
        allowLoopbackHttp: true,
      ),
      isTrue,
    );
  });
}
