class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'Kairos_API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
}
