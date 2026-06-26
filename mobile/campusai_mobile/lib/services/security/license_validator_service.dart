class LicenseValidatorService {
  const LicenseValidatorService();
  bool valid(String license) => license.trim().isNotEmpty;
}
