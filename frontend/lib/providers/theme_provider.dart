// Remembers the paper / chalkboard choice between app starts.
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'foodloop_theme';

  /// Paper (light) is the default look of the app.
  ThemeMode mode = ThemeMode.light;

  bool get isChalkboard => mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setChalkboard(bool on) async {
    mode = on ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, on ? 'dark' : 'light');
  }
}
