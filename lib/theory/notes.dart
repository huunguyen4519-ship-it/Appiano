import 'package:flutter/material.dart';

import '../core/settings_store.dart';

const List<String> _letterNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];
const List<String> _numberNames = [
  '1', '1#', '2', '2#', '3', '4', '4#', '5', '5#', '6', '6#', '7',
];
const List<String> _solfegeNames = [
  'Đô', 'Đô#', 'Rê', 'Rê#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',
];

/// Tên nốt kèm quãng tám, ví dụ 60 -> C4.
String noteName(int midi) => '${_letterNames[midi % 12]}${midi ~/ 12 - 1}';

/// Nhãn hiển thị trên phím theo kiểu đã chọn. Trả về null nếu tắt.
String? noteLabel(int midi, NoteLabelMode mode) {
  final i = midi % 12;
  return switch (mode) {
    NoteLabelMode.off => null,
    NoteLabelMode.letters => noteName(midi),
    NoteLabelMode.numbers => _numberNames[i],
    NoteLabelMode.solfege => _solfegeNames[i],
  };
}

const List<Color> _octaveColors = [
  Color(0xFFFFD166), // quãng tám 2: vàng
  Color(0xFFEF8354), // quãng tám 3: cam
  Color(0xFF06D6A0), // quãng tám 4: xanh ngọc
  Color(0xFF4CC9F0), // quãng tám 5: xanh dương
  Color(0xFFB388FF), // quãng tám 6: tím
];

/// Màu nền nhãn phím trắng theo quãng tám.
Color octaveColor(int midi) {
  final index = (midi ~/ 12 - 1) - 2;
  final clamped = index < 0
      ? 0
      : (index >= _octaveColors.length ? _octaveColors.length - 1 : index);
  return _octaveColors[clamped];
}

/// Chuỗi sao, ví dụ 2 -> ★★☆.
String starsText(int stars) => '★' * stars + '☆' * (3 - stars);
