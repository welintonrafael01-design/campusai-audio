class StudentDashboardSessionToken {
  final String ownerUserId;
  final int generation;

  const StudentDashboardSessionToken({
    required this.ownerUserId,
    required this.generation,
  });
}

class StaleStudentDashboardSession implements Exception {
  const StaleStudentDashboardSession();

  @override
  String toString() => 'Student dashboard session is no longer active.';
}

/// Owns transient Student Dashboard state for one authenticated session.
class StudentDashboardSessionIsolation {
  static String? _activeOwnerUserId;
  static int _generation = 0;
  static Object? _cachedData;
  static DateTime? _cachedAt;
  static String? _cachedOwnerUserId;
  static int? _cachedGeneration;

  const StudentDashboardSessionIsolation._();

  static StudentDashboardSessionToken capture(String ownerUserId) {
    final owner = ownerUserId.trim();
    if (owner.isEmpty || owner == 'guest') {
      throw const StaleStudentDashboardSession();
    }
    synchronizeAuthenticatedUser(owner);
    return StudentDashboardSessionToken(
      ownerUserId: owner,
      generation: _generation,
    );
  }

  static void synchronizeAuthenticatedUser(String? ownerUserId) {
    final owner = ownerUserId?.trim() ?? '';
    if (owner.isEmpty || owner == 'guest') {
      if (_activeOwnerUserId != null || _cachedData != null) {
        invalidateAuthenticatedState();
      }
      return;
    }
    if (_activeOwnerUserId == owner) return;

    _generation++;
    _activeOwnerUserId = owner;
    _clearCache();
  }

  static bool isCurrent(
    StudentDashboardSessionToken token,
    String currentOwnerUserId,
  ) {
    return currentOwnerUserId.trim() == token.ownerUserId &&
        _activeOwnerUserId == token.ownerUserId &&
        _generation == token.generation;
  }

  static T? read<T>(
    StudentDashboardSessionToken token,
    String currentOwnerUserId, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    if (!isCurrent(token, currentOwnerUserId) ||
        _cachedOwnerUserId != token.ownerUserId ||
        _cachedGeneration != token.generation ||
        _cachedAt == null ||
        DateTime.now().difference(_cachedAt!) >= ttl) {
      return null;
    }
    return _cachedData as T?;
  }

  static bool write(
    StudentDashboardSessionToken token,
    String currentOwnerUserId,
    Object data,
  ) {
    if (!isCurrent(token, currentOwnerUserId)) return false;

    _cachedData = data;
    _cachedAt = DateTime.now();
    _cachedOwnerUserId = token.ownerUserId;
    _cachedGeneration = token.generation;
    return true;
  }

  static void clearCache() => _clearCache();

  static void invalidateAuthenticatedState() {
    _generation++;
    _activeOwnerUserId = null;
    _clearCache();
  }

  static void _clearCache() {
    _cachedData = null;
    _cachedAt = null;
    _cachedOwnerUserId = null;
    _cachedGeneration = null;
  }

  static void debugResetForTesting() {
    _generation = 0;
    _activeOwnerUserId = null;
    _clearCache();
  }
}
