import 'dart:typed_data';

import 'lesson.dart';
import 'lesson_format.dart';

/// Đọc file MIDI chuẩn (định dạng 0 hoặc 1) thành bài học.
/// Các nốt bắt đầu cùng một thời điểm được gom thành một bước (hợp âm).
/// Không đọc tempo và nhịp, không đọc kênh trống (kênh 10).
Lesson lessonFromMidi(
  Uint8List bytes, {
  required String id,
  required String title,
}) {
  if (bytes.length > maxImportBytes) {
    throw const FormatException('File quá lớn (tối đa 1 MB).');
  }
  final r = _Reader(bytes);
  if (!r.matchAscii('MThd')) {
    throw const FormatException('File này không phải MIDI.');
  }
  final headerLength = r.u32();
  final headerEnd = r.pos + headerLength;
  r.u16(); // định dạng
  final trackCount = r.u16();
  final division = r.u16();
  if (division & 0x8000 != 0) {
    throw const FormatException('File MIDI kiểu SMPTE chưa được hỗ trợ.');
  }
  r.pos = headerEnd;

  final onsets = <(int, int)>[]; // (thời điểm, số MIDI)
  for (var t = 0; t < trackCount && !r.atEnd; t++) {
    if (!r.matchAscii('MTrk')) {
      throw const FormatException('File MIDI bị hỏng (thiếu đoạn track).');
    }
    final end = r.pos + r.u32();
    var tick = 0;
    var runningStatus = 0;
    while (r.pos < end) {
      tick += r.varLength();
      var status = r.u8();
      if (status < 0x80) {
        // Trạng thái lặp lại: byte vừa đọc là dữ liệu của lệnh trước.
        r.pos--;
        status = runningStatus;
      } else if (status < 0xF0) {
        runningStatus = status;
      }

      if (status == 0xFF) {
        final type = r.u8();
        r.pos += r.varLength();
        if (type == 0x2F) break; // hết track
        continue;
      }
      if (status == 0xF0 || status == 0xF7) {
        r.pos += r.varLength();
        continue;
      }

      final kind = status & 0xF0;
      final channel = status & 0x0F;
      if (kind == 0xC0 || kind == 0xD0) {
        r.u8(); // lệnh chỉ có một byte dữ liệu
        continue;
      }
      final note = r.u8();
      final velocity = r.u8();
      if (kind == 0x90 && velocity > 0 && channel != 9) {
        onsets.add((tick, note));
      }
    }
    r.pos = end;
  }

  final usable = onsets
      .where((e) => e.$2 >= 21 && e.$2 <= 108)
      .toList()
    ..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  if (usable.isEmpty) {
    throw const FormatException('File MIDI không có nốt nhạc nào trong phạm vi bàn phím.');
  }

  final steps = <LessonStep>[];
  var i = 0;
  while (i < usable.length) {
    final tick = usable[i].$1;
    final notes = <int>[];
    while (i < usable.length && usable[i].$1 == tick) {
      if (!notes.contains(usable[i].$2)) notes.add(usable[i].$2);
      i++;
    }
    steps.add(LessonStep(notes));
  }
  if (steps.length > maxLessonSteps) {
    throw FormatException('Bài MIDI có ${steps.length} bước, tối đa $maxLessonSteps bước.');
  }

  return Lesson(
    id: id,
    title: title,
    description: 'Nhập từ MIDI · ${steps.length} bước',
    steps: steps,
    imported: true,
  );
}

class _Reader {
  final Uint8List bytes;
  int pos = 0;

  _Reader(this.bytes);

  bool get atEnd => pos >= bytes.length;

  int u8() {
    _check(1);
    return bytes[pos++];
  }

  int u16() => (u8() << 8) | u8();

  int u32() => (u8() << 24) | (u8() << 16) | (u8() << 8) | u8();

  /// Số có độ dài thay đổi (tối đa 4 byte), dùng cho thời gian và độ dài.
  int varLength() {
    var value = 0;
    for (var k = 0; k < 4; k++) {
      final b = u8();
      value = (value << 7) | (b & 0x7F);
      if (b & 0x80 == 0) return value;
    }
    return value;
  }

  bool matchAscii(String s) {
    if (pos + s.length > bytes.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (bytes[pos + i] != s.codeUnitAt(i)) return false;
    }
    pos += s.length;
    return true;
  }

  void _check(int n) {
    if (pos + n > bytes.length) {
      throw const FormatException('File MIDI bị cắt cụt.');
    }
  }
}
