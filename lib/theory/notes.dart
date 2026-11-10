const List<String> _letterNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Tên nốt kèm quãng tám, ví dụ 60 -> C4.
String noteName(int midi) => '${_letterNames[midi % 12]}${midi ~/ 12 - 1}';

/// Chuỗi sao, ví dụ 2 -> ★★☆.
String starsText(int stars) => '★' * stars + '☆' * (3 - stars);
