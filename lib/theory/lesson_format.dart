import 'dart:convert';

import 'lesson.dart';

/// Giới hạn để file không làm treo app.
const int maxLessonSteps = 500;
const int maxImportBytes = 1024 * 1024;

const int _minMidi = 21; // A0
const int _maxMidi = 108; // C8

const Map<String, int> _letterPitch = {
  'C': 0,
  'D': 2,
  'E': 4,
  'F': 5,
  'G': 7,
  'A': 9,
  'B': 11,
};

/// Đổi tên nốt sang số MIDI: "C4" -> 60, "F#4" -> 66, "Bb4" -> 70.
/// Trả về null nếu sai định dạng.
int? midiFromName(String name) {
  final m = RegExp(r'^([A-Ga-g])([#b]?)(-?\d+)$').firstMatch(name.trim());
  if (m == null) return null;
  final pitch = _letterPitch[m.group(1)!.toUpperCase()]!;
  final accidental = switch (m.group(2)) {
    '#' => 1,
    'b' => -1,
    _ => 0,
  };
  return (int.parse(m.group(3)!) + 1) * 12 + pitch + accidental;
}

/// Đọc bài học từ chuỗi JSON. Ném [FormatException] kèm lời nhắn tiếng Việt nếu sai.
///
/// Định dạng:
/// {
///   "title": "Tên bài",
///   "description": "Mô tả ngắn",
///   "theory": ["..."],
///   "tips": ["..."],
///   "steps": [ {"notes": ["C4", "E4"], "fingers": [1, 3]}, {"notes": [67]} ]
/// }
Lesson lessonFromJsonText(String text, {required String id}) {
  if (utf8.encode(text).length > maxImportBytes) {
    throw const FormatException('File quá lớn (tối đa 1 MB).');
  }
  final Object? data;
  try {
    data = jsonDecode(text);
  } on FormatException {
    throw const FormatException('File không phải JSON hợp lệ.');
  }
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Nội dung JSON phải là một đối tượng { ... }.');
  }

  final title = data['title'];
  if (title is! String || title.trim().isEmpty) {
    throw const FormatException('Thiếu "title" (tên bài).');
  }

  final rawSteps = data['steps'];
  if (rawSteps is! List || rawSteps.isEmpty) {
    throw const FormatException('Thiếu "steps" (danh sách bước).');
  }
  if (rawSteps.length > maxLessonSteps) {
    throw FormatException('Bài có tối đa $maxLessonSteps bước.');
  }

  final steps = <LessonStep>[];
  for (var i = 0; i < rawSteps.length; i++) {
    final raw = rawSteps[i];
    final where = 'Bước ${i + 1}';
    if (raw is! Map<String, dynamic>) {
      throw FormatException('$where phải là một đối tượng { ... }.');
    }
    final rawNotes = raw['notes'];
    if (rawNotes is! List || rawNotes.isEmpty) {
      throw FormatException('$where thiếu "notes".');
    }
    final notes = [for (final n in rawNotes) _midiOf(n, where)];

    var fingers = <int>[];
    final rawFingers = raw['fingers'];
    if (rawFingers != null) {
      if (rawFingers is! List || rawFingers.length != notes.length) {
        throw FormatException(
          '$where: "fingers" phải có đúng ${notes.length} số.',
        );
      }
      fingers = [for (final f in rawFingers) _fingerOf(f, where)];
    }
    steps.add(LessonStep(notes, fingers));
  }

  return Lesson(
    id: id,
    title: title.trim(),
    description: data['description'] is String
        ? (data['description'] as String).trim()
        : '',
    theory: _textList(data['theory'], 'theory'),
    tips: _textList(data['tips'], 'tips'),
    steps: steps,
    imported: true,
  );
}

/// Đổi bài học thành JSON để lưu trên máy.
Map<String, Object?> lessonToJson(Lesson lesson) => {
      'id': lesson.id,
      'title': lesson.title,
      'description': lesson.description,
      'theory': lesson.theory,
      'tips': lesson.tips,
      'steps': [
        for (final s in lesson.steps)
          {
            'notes': s.notes,
            if (s.fingers.isNotEmpty) 'fingers': s.fingers,
          },
      ],
    };

int _midiOf(Object? n, String where) {
  final midi = switch (n) {
    int v => v,
    String s => midiFromName(s),
    _ => null,
  };
  if (midi == null || midi < _minMidi || midi > _maxMidi) {
    throw FormatException(
      '$where có nốt không hợp lệ: $n (dùng tên như C4, F#4 hoặc số MIDI từ 21 đến 108).',
    );
  }
  return midi;
}

int _fingerOf(Object? f, String where) {
  if (f is! int || f < 1 || f > 5) {
    throw FormatException('$where có số ngón không hợp lệ: $f (chỉ từ 1 đến 5).');
  }
  return f;
}

List<String> _textList(Object? v, String key) {
  if (v == null) return const [];
  if (v is! List || v.any((e) => e is! String)) {
    throw FormatException('"$key" phải là danh sách chữ.');
  }
  return [for (final e in v) (e as String).trim()];
}
