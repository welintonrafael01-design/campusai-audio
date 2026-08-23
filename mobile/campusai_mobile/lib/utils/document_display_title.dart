String documentDisplayTitle(String fileName) {
  var title = fileName.trim().replaceAll('\\', '/').split('/').last.trim();

  title = title.replaceFirst(
    RegExp(
      r'^(?:\d{18}|[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})[-_]+',
    ),
    '',
  );
  title = title.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
  title = title.replaceAll('_', ' ');

  final parts = title.split('-');
  if (parts.length > 1) {
    final buffer = StringBuffer(parts.first);

    for (var index = 1; index < parts.length; index++) {
      final previous = parts[index - 1];
      final current = parts[index];
      final keepsNumericSeparator = previous.isNotEmpty &&
          current.isNotEmpty &&
          RegExp(r'\d$').hasMatch(previous) &&
          RegExp(r'^\d').hasMatch(current);

      buffer.write(keepsNumericSeparator ? '-' : ' ');
      buffer.write(current);
    }

    title = buffer.toString();
  }

  title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  return title.isEmpty ? 'Documento' : title;
}
