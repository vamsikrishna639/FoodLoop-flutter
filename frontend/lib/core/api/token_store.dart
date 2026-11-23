// Saves the login token on the device so the session survives a restart.
// Android uses encrypted secure storage. Browsers have no equivalent, so the
// web build falls back to shared_preferences (localStorage).
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'foodloop_token';
  static const _secure = FlutterSecureStorage();

  Future<String?> read() async {
    try {
      if (kIsWeb) return (await SharedPreferences.getInstance()).getString(_key);
      return await _secure.read(key: _key);
    } catch (_) {
      return null; // unreadable storage is treated as "not logged in"
    }
  }

  Future<void> write(String token) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).setString(_key, token);
    } else {
      await _secure.write(key: _key, value: token);
    }
  }

  Future<void> clear() async {
    try {
      if (kIsWeb) {
        await (await SharedPreferences.getInstance()).remove(_key);
      } else {
        await _secure.delete(key: _key);
      }
    } catch (_) {/* nothing useful to do if clearing fails */}
  }
}
