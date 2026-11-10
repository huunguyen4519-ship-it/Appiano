import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiểu tên hiển thị trên phím.
enum NoteLabelMode { off, letters, numbers, solfege }

const int minVisibleWhites = 7;
const int maxVisibleWhites = 24;

/// Cài đặt người dùng, lưu trên máy.
class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _visibleKey = 'visible_whites';
  static const _labelKey = 'label_mode';

  /// Số phím trắng hiển thị cùng lúc.
  final ValueNotifier<int> visibleWhites = ValueNotifier<int>(10);

  /// Kiểu tên phím.
  final ValueNotifier<NoteLabelMode> labelMode =
      ValueNotifier<NoteLabelMode>(NoteLabelMode.letters);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_visibleKey);
      if (v != null) {
        visibleWhites.value = v.clamp(minVisibleWhites, maxVisibleWhites);
      }
      final m = prefs.getInt(_labelKey);
      if (m != null && m >= 0 && m < NoteLabelMode.values.length) {
        labelMode.value = NoteLabelMode.values[m];
      }
    } catch (_) {}
  }

  Future<void> setVisibleWhites(int value) async {
    visibleWhites.value = value.clamp(minVisibleWhites, maxVisibleWhites);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_visibleKey, visibleWhites.value);
    } catch (_) {}
  }

  Future<void> setLabelMode(NoteLabelMode mode) async {
    labelMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_labelKey, mode.index);
    } catch (_) {}
  }
}

const List<String> _letterNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];
const List<String> _numberNames = [
  '1', '1#', '2', '2#', '3', '4', '4#', '5', '5#', '6', '6#', '7',
];
const List<String> _solfegeNames = [
  'Đô', 'Đô#', 'Rê', 'Rê#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',
];

/// Nhãn của một nốt theo kiểu đã chọn. Trả về null nếu tắt.
String? noteLabel(int midi, NoteLabelMode mode) {
  final i = midi % 12;
  return switch (mode) {
    NoteLabelMode.off => null,
    NoteLabelMode.letters => _letterNames[i],
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

/// Màu nhãn của phím trắng theo quãng tám, để nhìn là biết đang ở vùng âm nào.
Color octaveColor(int midi) {
  final index = (midi ~/ 12 - 1) - 2;
  return _octaveColors[index.clamp(0, _octaveColors.length - 1)];
}
