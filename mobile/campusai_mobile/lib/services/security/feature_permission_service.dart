class FeaturePermissionService {
  const FeaturePermissionService();
  bool allows(Set<String> permissions, String feature) =>
      permissions.contains(feature) || permissions.contains('*');
}
