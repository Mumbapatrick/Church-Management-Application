import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class EnvConfig {
  /// Google OAuth Web Client ID
  /// Injected at build time using --dart-define
  /// flutter run --dart-define=WEB_CLIENT_ID=your_client_id
  static const String webClientId =
  String.fromEnvironment('WEB_CLIENT_ID', defaultValue: '');

  /// Optional: checks if the WEB_CLIENT_ID is loaded
  static bool get hasWebClientId => webClientId.isNotEmpty;

  /// Optional debug method: prints current config values
  /// Call once in main() to confirm values
  static void printDebug() {
    if (hasWebClientId) {
      print('WEB_CLIENT_ID loaded: $webClientId');
    } else {
      print(' WEB_CLIENT_ID is missing! Did you forget --dart-define?');
    }
  }
}
