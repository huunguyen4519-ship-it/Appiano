import 'package:appiano/features/practice/practice_session.dart';
import 'package:appiano/theory/lessons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lesson = Lesson(
    id: 'test',
    title: 'Thử',
    description: '',
    notes: [60, 62, 64],
    fingers: [1, 2, 3],
  );

  test('bấm đúng nốt thì đi tiếp', () {
    final s = PracticeSession(lesson);
    expect(s.press(60), PressResult.correct);
    expect(s.target, 62);
    expect(s.finger, 2);
  });

  test('bấm sai thì giữ nguyên nốt cần bấm và đếm lỗi', () {
    final s = PracticeSession(lesson);
    expect(s.press(61), PressResult.wrong);
    expect(s.target, 60);
    expect(s.mistakes, 1);
  });

  test('không sai thì được 3 sao', () {
    final s = PracticeSession(lesson);
    s.press(60);
    s.press(62);
    s.press(64);
    expect(s.finished, isTrue);
    expect(s.stars, 3);
  });

  test('sai 1 đến 2 lần thì được 2 sao, nhiều hơn thì 1 sao', () {
    final two = PracticeSession(lesson)
      ..press(61)
      ..press(60)
      ..press(62)
      ..press(64);
    expect(two.stars, 2);

    final many = PracticeSession(lesson)
      ..press(61)
      ..press(61)
      ..press(61)
      ..press(60)
      ..press(62)
      ..press(64);
    expect(many.stars, 1);
  });

  test('sau khi xong thì bấm nữa bị bỏ qua', () {
    final s = PracticeSession(lesson)
      ..press(60)
      ..press(62)
      ..press(64);
    expect(s.press(60), PressResult.ignored);
  });

  test('làm lại thì về đầu và xóa lỗi', () {
    final s = PracticeSession(lesson)
      ..press(61)
      ..press(60);
    s.restart();
    expect(s.index, 0);
    expect(s.mistakes, 0);
  });
}
