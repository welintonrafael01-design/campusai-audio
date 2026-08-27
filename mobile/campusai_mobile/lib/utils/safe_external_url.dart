bool isSafeExternalUri(
  Uri uri, {
  bool allowLoopbackHttp = false,
}) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https') return uri.host.isNotEmpty;

  if (scheme != 'http' || !allowLoopbackHttp) return false;

  final host = uri.host.toLowerCase();
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
