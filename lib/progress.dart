import 'package:shared_preferences/shared_preferences.dart';

/// Lưu tiến độ trên máy. Nếu lỗi thì app vẫn chạy, chỉ không lưu được.
class Progress {
  static const _key = 'completed_lessons';

  static Future<Set<String>> completed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? const <String>[]).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markCompleted(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(_key) ?? const <String>[]).toSet()
        ..add(id);
      await prefs.setStringList(_key, ids.toList());
    } catch (_) {}
  }
}
