/// Bài học. Các nốt là số MIDI (C4 = 60, C5 = 72).
/// [fingers] là số ngón tay tay phải cho từng nốt (1 = ngón cái).
class Lesson {
  final String id;
  final String title;
  final String description;
  final List<int> notes;
  final List<int> fingers;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.notes,
    required this.fingers,
  });
}

const List<Lesson> lessons = [
  Lesson(
    id: 'scale-up',
    title: 'Thang âm đi lên',
    description: 'C D E F G A B C',
    notes: [60, 62, 64, 65, 67, 69, 71, 72],
    fingers: [1, 2, 3, 1, 2, 3, 4, 5],
  ),
  Lesson(
    id: 'scale-down',
    title: 'Thang âm đi xuống',
    description: 'C B A G F E D C',
    notes: [72, 71, 69, 67, 65, 64, 62, 60],
    fingers: [5, 4, 3, 2, 1, 3, 2, 1],
  ),
  Lesson(
    id: 'c-chord',
    title: 'Hợp âm Đô trưởng',
    description: 'C E G, rồi quay lại',
    notes: [60, 64, 67, 64, 60],
    fingers: [1, 3, 5, 3, 1],
  ),
  Lesson(
    id: 'ode-to-joy',
    title: 'Niềm vui (đoạn đầu)',
    description: 'Giai điệu quen thuộc, 15 nốt',
    notes: [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62],
    fingers: [3, 3, 4, 5, 5, 4, 3, 2, 1, 1, 2, 3, 3, 2, 2],
  ),
];
