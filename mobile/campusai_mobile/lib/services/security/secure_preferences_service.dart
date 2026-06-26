class SecurePreferencesService {
  const SecurePreferencesService();
  bool canStore(String key) => !key.toLowerCase().contains('secret');
}
