class PremiumValidatorService {
  const PremiumValidatorService();
  bool enabled(bool licensed, bool flag) => licensed && flag;
}
