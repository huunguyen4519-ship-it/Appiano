import 'package:flutter/material.dart';

import '../../theory/notation.dart';
import 'keyboard_palette.dart';

/// Vẽ toàn bộ phím trong một lần vẽ. Nhanh hơn nhiều so với một widget cho mỗi phím.
/// Chỉ biết cách vẽ. Không biết âm thanh, không biết ký âm nào đang dùng.
class KeysPainter extends CustomPainter {
  final List<int> whites;
  final List<({int midi, int leftWhite})> blacks;
  final double start;
  final int visible;
  final Set<int> pressed;
  final Set<int> highlight;
  final int? wrong;
  final Map<int, String> labels;

  /// Ký âm đang dùng. Null nghĩa là ẩn nhãn.
  final NoteNotation? notation;
  final KeyboardPalette palette;

  /// Màu nhấn khi bấm phím, đã được chọn sẵn bởi người gọi.
  final Color accent;

  KeysPainter({
    required this.whites,
    required this.blacks,
    required this.start,
    required this.visible,
    required this.pressed,
    required this.highlight,
    required this.wrong,
    required this.labels,
    required this.notation,
    required this.palette,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whiteW = size.width / visible;
    final blackW = whiteW * 0.6;
    final blackH = size.height * 0.62;

    for (int i = 0; i < whites.length; i++) {
      final left = (i - start) * whiteW;
      if (left < -whiteW || left > size.width) continue;
      final midi = whites[i];
      _drawKey(
        canvas,
        Rect.fromLTWH(left + 1, 0, whiteW - 2, size.height),
        _whiteColors(midi),
        black: false,
        pressed: pressed.contains(midi),
        radius: 10,
        label: labels[midi] ?? notation?.labelFor(midi),
        labelColor: palette.labelOnWhite,
        fontSize: (whiteW * 0.24).clamp(9.0, 14.0).toDouble(),
        // Nhãn nằm ngay dưới chân phím đen, trên thân phím trắng.
        labelTop: blackH + 8,
      );
    }

    for (final b in blacks) {
      final left = (b.leftWhite - start + 1) * whiteW - blackW / 2;
      if (left < -blackW || left > size.width) continue;
      _drawKey(
        canvas,
        Rect.fromLTWH(left, 0, blackW, blackH),
        _blackColors(b.midi),
        black: true,
        pressed: pressed.contains(b.midi),
        radius: 6,
        labelColor: Colors.white,
        fontSize: 0,
      );
    }
  }

  List<Color> _pressedColors(bool black) {
    return black
        ? [Color.lerp(accent, Colors.white, 0.25)!, accent]
        : [Color.lerp(accent, Colors.white, 0.6)!, accent];
  }

  List<Color> _whiteColors(int midi) {
    if (wrong == midi) return palette.wrongWhite;
    if (pressed.contains(midi)) return _pressedColors(false);
    if (highlight.contains(midi)) return palette.highlightWhite;
    return palette.whiteGradient;
  }

  List<Color> _blackColors(int midi) {
    if (wrong == midi) return palette.wrongBlack;
    if (pressed.contains(midi)) return _pressedColors(true);
    if (highlight.contains(midi)) return palette.highlightBlack;
    return palette.blackGradient;
  }

  void _drawKey(
    Canvas canvas,
    Rect baseRect,
    List<Color> colors, {
    required bool black,
    required bool pressed,
    required double radius,
    String? label,
    required Color labelColor,
    required double fontSize,
    double? labelTop,
  }) {
    // Phím bị bấm thì lún xuống một chút, bóng nhỏ lại: cảm giác phím thật.
    final rect = pressed ? baseRect.shift(const Offset(0, 2)) : baseRect;
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    final shadowOffset = pressed ? 1.0 : (black ? 5.0 : 2.0);

    canvas.drawRRect(
      rrect.shift(Offset(0, shadowOffset)),
      Paint()
        ..color = Colors.black.withValues(alpha: black ? 0.7 : 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, black ? 4 : 2),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = black ? Colors.black : palette.whiteBorder,
    );

    if (label == null || labelTop == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w500,
          fontSize: fontSize,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, labelTop),
    );
  }

  @override
  bool shouldRepaint(covariant KeysPainter old) => true;
}
