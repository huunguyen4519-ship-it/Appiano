/// Cách ký âm hiển thị trên phím trắng.
/// Thêm kiểu mới bằng cách thêm một lớp mới, không cần sửa bàn phím.
abstract class NoteNotation {
  const NoteNotation();

  /// Mã lưu trong cài đặt. Không đổi sau khi phát hành.
  String get id;

  /// Tên hiển thị trong Cài đặt.
  String get displayName;

  /// Nhãn cho phím trắng. Trả về null cho phím đen.
  String? labelFor(int midi);
}

const Map<int, int> _whiteDegree = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};

/// Bậc trong thang Đô trưởng (0 = Đô), hoặc null nếu là phím đen.
int? whiteDegree(int midi) => _whiteDegree[midi % 12];

/// Quãng tám theo chuẩn quốc tế: C4 thuộc quãng tám 4.
int octaveOf(int midi) => midi ~/ 12 - 1;

/// C D E F G A B. Chỉ phím Đô có kèm quãng tám (C4, C5) để biết đang ở đâu.
class LetterNotation extends NoteNotation {
  const LetterNotation();

  static const List<String> _names = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

  @override
  String get id => 'letters';

  @override
  String get displayName => 'C D E';

  @override
  String? labelFor(int midi) {
    final d = whiteDegree(midi);
    if (d == null) return null;
    return d == 0 ? '${_names[d]}${octaveOf(midi)}' : _names[d];
  }
}

/// Đô Rê Mi Fa Sol La Si (xướng âm).
class SolfegeNotation extends NoteNotation {
  const SolfegeNotation();

  static const List<String> _names = [
    'Đô', 'Rê', 'Mi', 'Fa', 'Sol', 'La', 'Si',
  ];

  @override
  String get id => 'solfege';

  @override
  String get displayName => 'Đô Rê';

  @override
  String? labelFor(int midi) {
    final d = whiteDegree(midi);
    return d == null ? null : _names[d];
  }
}

/// Ký âm số Jianpu: 1 2 3 4 5 6 7. Chấm trên là quãng cao hơn, chấm dưới là thấp hơn.
class JianpuNotation extends NoteNotation {
  const JianpuNotation();

  static const List<String> _digits = ['1', '2', '3', '4', '5', '6', '7'];

  @override
  String get id => 'jianpu';

  @override
  String get displayName => '1 2 3';

  @override
  String? labelFor(int midi) {
    final d = whiteDegree(midi);
    if (d == null) return null;
    final shift = octaveOf(midi) - 4;
    final dots = shift > 0 ? '̇' * shift : '̣' * -shift;
    return '${_digits[d]}$dots';
  }
}

/// Các kiểu ký âm người dùng có thể chọn, theo thứ tự hiển thị.
const List<NoteNotation> notationChoices = [
  LetterNotation(),
  SolfegeNotation(),
  JianpuNotation(),
];
