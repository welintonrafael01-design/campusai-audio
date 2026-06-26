class RoleValidator {
  const RoleValidator();
  bool canAccess(String role, String requiredRole) {
    const order = [
      'student',
      'teacher',
      'coordinator',
      'department',
      'institution',
      'super_admin'
    ];
    return order.indexOf(role) >= order.indexOf(requiredRole);
  }
}

class InstitutionValidator {
  const InstitutionValidator();
  bool validTenant(String tenantId) => tenantId.trim().isNotEmpty;
}

class AuditTrailEntry {
  final String actorId;
  final String action;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AuditTrailEntry({
    this.actorId = '',
    this.action = '',
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'actor_id': actorId,
        'action': action,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };
}

class AuditTrail {
  final List<AuditTrailEntry> entries;
  const AuditTrail({this.entries = const []});
  AuditTrail add(AuditTrailEntry entry) =>
      AuditTrail(entries: [...entries, entry]);
}
