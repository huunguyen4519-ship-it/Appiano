/// Bài học. Các nốt là số MIDI (C4 = 60, C5 = 72).
class Lesson {
  final String id;
  final String title;
  final String description;
  final List<int> notes;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.notes,
  });
}

const List<Lesson> lessons = [
  Lesson(
    id: 'scale-up',
    title: 'Thang âm đi lên',
    description: 'C D E F G A B C',
    notes: [60, 62, 64, 65, 67, 69, 71, 72],
  ),
  Lesson(
    id: 'scale-down',
    title: 'Thang âm đi xuống',
    description: 'C B A G F E D C',
    notes: [72, 71, 69, 67, 65, 64, 62, 60],
  ),
  Lesson(
    id: 'c-chord',
    title: 'Hợp âm Đô trưởng',
    description: 'C E G, rồi quay lại',
    notes: [60, 64, 67, 64, 60],
  ),
  Lesson(
    id: 'ode-to-joy',
    title: 'Niềm vui (đoạn đầu)',
    description: 'Giai điệu quen thuộc, 15 nốt',
    notes: [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62],
  ),
];

const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Tên nốt, ví dụ 60 -> C4.
String noteName(int midi) => '${_noteNames[midi % 12]}${midi ~/ 12 - 1}';
