import 'package:flutter/material.dart';

/// Bảng màu của bàn phím. Là dữ liệu thuần, nên mỗi màn hình chọn một bảng riêng.
class KeyboardPalette {
  const KeyboardPalette({
    this.accent,
    required this.whiteGradient,
    required this.blackGradient,
    required this.highlightWhite,
    required this.highlightBlack,
    required this.wrongWhite,
    required this.wrongBlack,
    required this.whiteBorder,
    required this.labelOnWhite,
    required this.overviewTrack,
    required this.overviewKey,
    required this.overviewWindow,
    this.overviewWindowBorder,
  });

  /// Màu khi phím đang được bấm. Null thì lấy màu chủ đề của app.
  final Color? accent;

  final List<Color> whiteGradient;
  final List<Color> blackGradient;
  final List<Color> highlightWhite;
  final List<Color> highlightBlack;
  final List<Color> wrongWhite;
  final List<Color> wrongBlack;
  final Color whiteBorder;
  final Color labelOnWhite;

  final Color overviewTrack;
  final Color overviewKey;
  final Color overviewWindow;

  /// Null thì lấy màu chủ đề của app.
  final Color? overviewWindowBorder;
}

/// Bảng màu gốc của app: phím trắng sáng, nhấn bằng màu chủ đề.
const KeyboardPalette defaultPalette = KeyboardPalette(
  whiteGradient: [Color(0xFFFFFFFF), Color(0xFFE6E6EE)],
  blackGradient: [Color(0xFF3A3A46), Color(0xFF0A0A0E)],
  highlightWhite: [Color(0xFFCFFAC4), Color(0xFF6BD16A)],
  highlightBlack: [Color(0xFF81C784), Color(0xFF1B5E20)],
  wrongWhite: [Color(0xFFFFB4AB), Color(0xFFE2574C)],
  wrongBlack: [Color(0xFFFF8A80), Color(0xFFB71C1C)],
  whiteBorder: Color(0xFFB0B0BC),
  labelOnWhite: Color(0x8C000000),
  overviewTrack: Color(0x59000000),
  overviewKey: Color(0xFF6E6E78),
  overviewWindow: Color(0x33FFFFFF),
);

/// Bảng màu tối giản cho màn Chơi tự do: than đậm, điểm nhấn đỏ trầm.
const KeyboardPalette charcoalPalette = KeyboardPalette(
  accent: Color(0xFFA3182F),
  whiteGradient: [Color(0xFFF4F4F6), Color(0xFFD2D2D8)],
  blackGradient: [Color(0xFF26262C), Color(0xFF060608)],
  highlightWhite: [Color(0xFFFFE8EB), Color(0xFFF0B8C2)],
  highlightBlack: [Color(0xFF7A1B2B), Color(0xFF3D0C15)],
  wrongWhite: [Color(0xFFA3182F), Color(0xFF6E0F1F)],
  wrongBlack: [Color(0xFFC2344A), Color(0xFF7A1B2B)],
  whiteBorder: Color(0xFF9A9AA3),
  labelOnWhite: Color(0x8C000000),
  overviewTrack: Color(0xFF1C1C22),
  overviewKey: Color(0xFF4A4A53),
  overviewWindow: Color(0x26FFFFFF),
  overviewWindowBorder: Color(0xFFEDEDF2),
);
