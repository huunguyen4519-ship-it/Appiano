/// Một bước luyện: một nốt, hoặc nhiều nốt bấm cùng lúc (hợp âm).
class LessonStep {
  /// Các nốt số MIDI (C4 = 60).
  final List<int> notes;

  /// Số ngón cho từng nốt, cùng thứ tự với [notes]. Có thể rỗng.
  final List<int> fingers;

  const LessonStep(this.notes, [this.fingers = const []]);

  /// Số ngón của một nốt trong bước này, hoặc null nếu không có.
  int? fingerOf(int midi) {
    final i = notes.indexOf(midi);
    if (i < 0 || i >= fingers.length) return null;
    return fingers[i];
  }
}

/// Bài học. [steps] là các bước theo thứ tự luyện.
class Lesson {
  final String id;
  final String title;
  final String description;

  /// Phần lý thuyết ngắn, hiển thị trước khi luyện.
  final List<String> theory;

  /// Lỗi thường gặp và mẹo.
  final List<String> tips;

  final List<LessonStep> steps;

  /// true nếu bài được nạp từ file, không phải giáo trình có sẵn.
  final bool imported;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.theory = const [],
    this.tips = const [],
    this.imported = false,
  });
}
