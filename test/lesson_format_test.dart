import 'dart:typed_data';

import 'package:appiano/theory/lesson_format.dart';
import 'package:appiano/theory/midi_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('đổi tên nốt sang số MIDI', () {
    expect(midiFromName('C4'), 60);
    expect(midiFromName('F#4'), 66);
    expect(midiFromName('Bb4'), 70);
    expect(midiFromName('H4'), isNull);
  });

  test('đọc bài JSON có hợp âm và số ngón', () {
    final lesson = lessonFromJsonText(
      '{"title":"Thử","steps":[{"notes":["C4","E4"],"fingers":[1,3]},{"notes":[67]}]}',
      id: 'x',
    );
    expect(lesson.imported, isTrue);
    expect(lesson.steps.length, 2);
    expect(lesson.steps[0].notes, [60, 64]);
    expect(lesson.steps[0].fingerOf(64), 3);
    expect(lesson.steps[1].notes, [67]);
  });

  test('JSON sai thì báo lỗi FormatException', () {
    expect(
      () => lessonFromJsonText('không phải json', id: 'x'),
      throwsFormatException,
    );
    expect(
      () => lessonFromJsonText(
        '{"title":"A","steps":[{"notes":["H9"]}]}',
        id: 'x',
      ),
      throwsFormatException,
    );
    expect(
      () => lessonFromJsonText(
        '{"title":"A","steps":[{"notes":[60],"fingers":[9]}]}',
        id: 'x',
      ),
      throwsFormatException,
    );
  });

  test('đọc MIDI: các nốt cùng thời điểm thành một bước', () {
    final bytes = Uint8List.fromList([
      // Đầu file: "MThd", độ dài 6, định dạng 0, 1 track, 96 tick mỗi phách.
      0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96,
      // Track: "MTrk", độ dài 28 byte.
      0x4D, 0x54, 0x72, 0x6B, 0, 0, 0, 0x1C,
      0x00, 0x90, 0x3C, 0x64, // tick 0: bật C4
      0x60, 0x80, 0x3C, 0x00, // tick 96: tắt C4
      0x00, 0x90, 0x40, 0x64, // tick 96: bật E4
      0x00, 0x90, 0x43, 0x64, // tick 96: bật G4
      0x60, 0x80, 0x40, 0x00, // tick 192: tắt E4
      0x00, 0x80, 0x43, 0x00, // tắt G4
      0x00, 0xFF, 0x2F, 0x00, // hết track
    ]);
    final lesson = lessonFromMidi(bytes, id: 'm', title: 'Thử MIDI');
    expect([for (final s in lesson.steps) s.notes], [
      [60],
      [64, 67],
    ]);
  });
}
