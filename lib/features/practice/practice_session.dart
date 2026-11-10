import '../../theory/lesson.dart';

/// Kết quả khi người chơi bấm một nốt trong bài.
enum PressResult { correct, wrong, ignored }

/// Trạng thái một lần luyện bài. Không phụ thuộc giao diện, nên kiểm thử được.
/// Mỗi bước có thể gồm nhiều nốt (hợp âm): phải bấm đủ các nốt mới sang bước sau.
class PracticeSession {
  PracticeSession(this.lesson);

  final Lesson lesson;

  int _index = 0;
  int _mistakes = 0;
  final Set<int> _hit = {};

  int get index => _index;
  int get mistakes => _mistakes;
  int get total => lesson.steps.length;
  bool get finished => _index >= total;

  /// Các nốt của bước hiện tại. Rỗng khi đã xong.
  Set<int> get targets =>
      finished ? const <int>{} : lesson.steps[_index].notes.toSet();

  /// Các nốt đã bấm đúng trong bước hiện tại.
  Set<int> get hit => Set.unmodifiable(_hit);

  /// Chữ số ngón hiển thị trên từng phím của bước hiện tại.
  Map<int, String> get fingerLabels {
    if (finished) return const <int, String>{};
    final step = lesson.steps[_index];
    return {
      for (final n in step.notes)
        if (step.fingerOf(n) != null) n: '${step.fingerOf(n)}',
    };
  }

  /// 0 sai: 3 sao. Sai 1-2 lần: 2 sao. Sai nhiều hơn: 1 sao.
  int get stars {
    if (_mistakes == 0) return 3;
    if (_mistakes <= 2) return 2;
    return 1;
  }

  PressResult press(int midi) {
    if (finished) return PressResult.ignored;
    if (!targets.contains(midi)) {
      _mistakes++;
      return PressResult.wrong;
    }
    if (_hit.contains(midi)) return PressResult.ignored;
    _hit.add(midi);
    if (_hit.length == targets.length) {
      _index++;
      _hit.clear();
    }
    return PressResult.correct;
  }

  void restart() {
    _index = 0;
    _mistakes = 0;
    _hit.clear();
  }
}
