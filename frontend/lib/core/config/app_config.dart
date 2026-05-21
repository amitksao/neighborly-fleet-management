class AppConfig {
  /// Override at build time with --dart-define=BASE_URL=https://your-api.com
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator → host localhost
  );
}
