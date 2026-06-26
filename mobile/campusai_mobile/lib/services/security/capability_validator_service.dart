class CapabilityValidatorService {
  const CapabilityValidatorService();
  bool valid(String capability) => capability.trim().isNotEmpty;
}
