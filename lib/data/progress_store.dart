import 'package:shared_preferences/shared_preferences.dart';

/// Lưu tiến độ (số sao cao nhất của mỗi bài) trên máy.
/// Nếu lỗi thì app vẫn chạy, chỉ là không lưu được.
class ProgressStore {
  ProgressStore._();

  static String _key(String id) => 'stars_$id';

  static Future<Map<String, int>> bestStars(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {for (final id in ids) id: prefs.getInt(_key(id)) ?? 0};
    } catch (_) {
      return {};
    }
  }

  /// Chỉ ghi đè khi lần này tốt hơn lần trước.
  static Future<void> saveStars(String id, int stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_key(id)) ?? 0;
      if (stars > best) await prefs.setInt(_key(id), stars);
    } catch (_) {}
  }
}
