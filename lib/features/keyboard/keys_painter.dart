import 'package:flutter/material.dart';

import '../../core/settings_store.dart';
import '../../theory/notes.dart';

/// Vẽ toàn bộ phím trong một lần vẽ, nhanh hơn nhiều so với một widget cho mỗi phím.
class KeysPainter extends CustomPainter {
  final List<int> whites;
  final List<({int midi, int leftWhite})> blacks;
  final double start;
  final int visible;
  final Set<int> pressed;
  final Set<int> highlight;
  final int? wrong;
  final Map<int, String> labels;
  final NoteLabelMode labelMode;
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
    required this.labelMode,
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
      final isLabelFromMode = labels[midi] == null;
      _drawKey(
        canvas,
        Rect.fromLTWH(left + 1, 0, whiteW - 2, size.height),
        _whiteColors(midi),
        black: false,
        pressed: pressed.contains(midi),
        radius: 10,
        label: labels[midi] ?? noteLabel(midi, labelMode),
        labelColor: Colors.black87,
        fontSize: (whiteW * 0.26).clamp(8.0, 16.0).toDouble(),
        pill: isLabelFromMode && labelMode != NoteLabelMode.off
            ? octaveColor(midi)
            : null,
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
        label: labels[b.midi] ?? noteLabel(b.midi, labelMode),
        labelColor: Colors.white,
        fontSize: (whiteW * 0.2).clamp(7.0, 12.0).toDouble(),
      );
    }
  }

  List<Color> _pressedColors(bool black) {
    return black
        ? [Color.lerp(accent, Colors.white, 0.25)!, accent]
        : [Color.lerp(accent, Colors.white, 0.6)!, accent];
  }

  List<Color> _whiteColors(int midi) {
    if (wrong == midi) return const [Color(0xFFFFB4AB), Color(0xFFE2574C)];
    if (pressed.contains(midi)) return _pressedColors(false);
    if (highlight.contains(midi)) {
      return const [Color(0xFFCFFAC4), Color(0xFF6BD16A)];
    }
    return const [Color(0xFFFFFFFF), Color(0xFFE6E6EE)];
  }

  List<Color> _blackColors(int midi) {
    if (wrong == midi) return const [Color(0xFFFF8A80), Color(0xFFB71C1C)];
    if (pressed.contains(midi)) return _pressedColors(true);
    if (highlight.contains(midi)) {
      return const [Color(0xFF81C784), Color(0xFF1B5E20)];
    }
    return const [Color(0xFF3A3A46), Color(0xFF0A0A0E)];
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
    Color? pill,
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
        ..color = black ? Colors.black : const Color(0xFFB0B0BC),
    );

    if (label == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = Offset(rect.center.dx - tp.width / 2, rect.bottom - tp.height - 8);
    if (pill != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - 5, pos.dy - 2, tp.width + 10, tp.height + 4),
          const Radius.circular(8),
        ),
        Paint()..color = pill,
      );
    }
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant KeysPainter old) => true;
}
