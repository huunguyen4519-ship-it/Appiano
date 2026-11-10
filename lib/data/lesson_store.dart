import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theory/lesson.dart';
import '../theory/lesson_format.dart';

/// Lưu các bài nạp từ file trên máy. Nếu lỗi thì app vẫn chạy, chỉ là không lưu được.
class LessonStore {
  LessonStore._();

  static const _key = 'imported_lessons_v1';

  static Future<List<Lesson>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <Lesson>[];
      for (final item in prefs.getStringList(_key) ?? const <String>[]) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          result.add(lessonFromJsonText(item, id: map['id'] as String));
        } catch (_) {
          // Bỏ qua một bài hỏng, các bài khác vẫn hiển thị.
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(Lesson lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = [...?prefs.getStringList(_key)];
      raw.add(jsonEncode(lessonToJson(lesson)));
      await prefs.setStringList(_key, raw);
    } catch (_) {}
  }

  static Future<void> remove(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = [...?prefs.getStringList(_key)];
      raw.removeWhere(
        (item) => (jsonDecode(item) as Map<String, dynamic>)['id'] == id,
      );
      await prefs.setStringList(_key, raw);
    } catch (_) {}
  }
}
