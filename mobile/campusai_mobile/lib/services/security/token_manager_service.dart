class TokenManagerService {
  const TokenManagerService();
  String redact(String token) =>
      token.length < 8 ? '[redacted]' : '${token.substring(0, 4)}...[redacted]';
}
