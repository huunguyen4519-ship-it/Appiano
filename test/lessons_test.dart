import 'package:flutter_test/flutter_test.dart';

import 'package:appiano/theory/lessons.dart';

void main() {
  test('mỗi bài có mã riêng và có ít nhất một bước', () {
    final ids = lessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final lesson in lessons) {
      expect(lesson.steps, isNotEmpty, reason: lesson.id);
    }
  });

  test('mọi nốt trong giáo trình nằm trong dải bàn phím (21-108)', () {
    for (final lesson in lessons) {
      for (final step in lesson.steps) {
        for (final midi in step.notes) {
          expect(midi, inInclusiveRange(21, 108), reason: lesson.id);
        }
      }
    }
  });
}
