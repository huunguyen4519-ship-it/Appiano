import 'package:appiano/features/practice/practice_session.dart';
import 'package:appiano/theory/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lesson = Lesson(
    id: 'test',
    title: 'Thử',
    description: '',
    steps: [
      LessonStep([60], [1]),
      LessonStep([62], [2]),
      LessonStep([64, 67], [3, 5]),
    ],
  );

  test('bấm đúng nốt thì đi tiếp', () {
    final s = PracticeSession(lesson);
    expect(s.press(60), PressResult.correct);
    expect(s.index, 1);
    expect(s.targets, {62});
    expect(s.fingerLabels, {62: '2'});
  });

  test('bấm sai thì giữ nguyên bước và đếm lỗi', () {
    final s = PracticeSession(lesson);
    expect(s.press(61), PressResult.wrong);
    expect(s.index, 0);
    expect(s.mistakes, 1);
  });

  test('hợp âm: phải bấm đủ các nốt mới sang bước sau', () {
    final s = PracticeSession(lesson)
      ..press(60)
      ..press(62);
    expect(s.index, 2);
    expect(s.press(64), PressResult.correct);
    expect(s.index, 2);
    expect(s.hit, {64});
    expect(s.press(67), PressResult.correct);
    expect(s.finished, isTrue);
  });

  test('bấm lặp cùng một nốt trong hợp âm thì bỏ qua', () {
    final s = PracticeSession(lesson)
      ..press(60)
      ..press(62)
      ..press(64);
    expect(s.press(64), PressResult.ignored);
    expect(s.mistakes, 0);
  });

  test('không sai thì được 3 sao', () {
    final s = PracticeSession(lesson)
      ..press(60)
      ..press(62)
      ..press(64)
      ..press(67);
    expect(s.finished, isTrue);
    expect(s.stars, 3);
  });

  test('sai 1 đến 2 lần thì được 2 sao, nhiều hơn thì 1 sao', () {
    final two = PracticeSession(lesson)
      ..press(61)
      ..press(60)
      ..press(63)
      ..press(62)
      ..press(64)
      ..press(67);
    expect(two.mistakes, 2);
    expect(two.stars, 2);

    final many = PracticeSession(lesson)
      ..press(61)
      ..press(61)
      ..press(61)
      ..press(60)
      ..press(62)
      ..press(64)
      ..press(67);
    expect(many.stars, 1);
  });

  test('sau khi xong thì bấm nữa bị bỏ qua', () {
    final s = PracticeSession(lesson)
      ..press(60)
      ..press(62)
      ..press(64)
      ..press(67);
    expect(s.press(60), PressResult.ignored);
  });

  test('làm lại thì về đầu và xóa lỗi', () {
    final s = PracticeSession(lesson)
      ..press(61)
      ..press(60);
    s.restart();
    expect(s.index, 0);
    expect(s.mistakes, 0);
    expect(s.hit, isEmpty);
  });
}
