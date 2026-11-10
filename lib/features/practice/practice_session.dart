import '../../theory/lessons.dart';

/// Kết quả khi người chơi bấm một nốt trong bài.
enum PressResult { correct, wrong, ignored }

/// Trạng thái một lần luyện bài. Không phụ thuộc giao diện, nên kiểm thử được.
class PracticeSession {
  PracticeSession(this.lesson);

  final Lesson lesson;

  int _index = 0;
  int _mistakes = 0;

  int get index => _index;
  int get mistakes => _mistakes;
  int get total => lesson.notes.length;
  bool get finished => _index >= total;

  /// Nốt cần bấm tiếp theo. Chỉ gọi khi chưa xong.
  int get target => lesson.notes[_index];

  /// Số ngón tay cho nốt cần bấm. Chỉ gọi khi chưa xong.
  int get finger => lesson.fingers[_index];

  /// 0 sai: 3 sao. Sai 1-2 lần: 2 sao. Sai nhiều hơn: 1 sao.
  int get stars {
    if (_mistakes == 0) return 3;
    if (_mistakes <= 2) return 2;
    return 1;
  }

  PressResult press(int midi) {
    if (finished) return PressResult.ignored;
    if (midi == target) {
      _index++;
      return PressResult.correct;
    }
    _mistakes++;
    return PressResult.wrong;
  }

  void restart() {
    _index = 0;
    _mistakes = 0;
  }
}
