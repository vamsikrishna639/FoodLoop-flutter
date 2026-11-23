// The one place that knows where the backend lives.
import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  /// Override at run time with:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    // In a browser the backend is on the same machine.
    if (kIsWeb) return 'http://localhost:5000/api';
    // Inside the Android emulator, "localhost" is the emulator itself;
    // 10.0.2.2 is the special address of the computer running it.
    return 'http://10.0.2.2:5000/api';
  }

  /// How often the activity feed refreshes while the app is visible.
  static const Duration activityPollInterval = Duration(seconds: 20);
}
