import 'package:flutter/material.dart';

import 'audio.dart';
import 'settings_store.dart';
import 'ui.dart';

/// Bàn phím có thể trượt qua nhiều quãng tám.
/// Thanh tổng quan ở trên: kéo hoặc chạm để chuyển vùng hiển thị, nút ◀ ▶ nhảy 1 quãng tám.
class PianoKeyboard extends StatefulWidget {
  /// Gọi mỗi khi người chơi chạm vào một nốt mới.
  final void Function(int midi) onNote;

  /// Các nốt cần tô xanh lá để gợi ý. Bàn phím tự trượt tới nốt đầu tiên.
  final Set<int> highlight;

  /// Nốt vừa bấm sai, tô đỏ thoáng qua.
  final int? wrong;

  /// Chữ ghi đè lên phím, ví dụ số ngón tay. Ưu tiên hơn kiểu tên nốt.
  final Map<int, String> labels;

  const PianoKeyboard({
    super.key,
    required this.onNote,
    this.highlight = const {},
    this.wrong,
    this.labels = const {},
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

const int _lowMidi = 36; // C2
const int _highMidi = 96; // C7
const int _octaveStep = 7;
const Set<int> _whiteSemitones = {0, 2, 4, 5, 7, 9, 11};

class _PianoKeyboardState extends State<PianoKeyboard> {
  late final List<int> _whites = [
    for (int m = _lowMidi; m <= _highMidi; m++)
      if (_whiteSemitones.contains(m % 12)) m,
  ];

  late final List<({int midi, int leftWhite})> _blacks = [
    for (int m = _lowMidi; m <= _highMidi; m++)
      if (!_whiteSemitones.contains(m % 12))
        (midi: m, leftWhite: _whites.indexOf(m - 1)),
  ];

  // Vị trí cuộn tính theo đơn vị phím trắng. Có thể là số lẻ để trượt mượt.
  double _startF = 0;

  final Map<int, int> _pointerNote = {}; // pointerId -> midi

  // Tách riêng trạng thái phím đang bấm để chỉ phần phím được vẽ lại, không dựng lại cả widget.
  final ValueNotifier<Set<int>> _pressed = ValueNotifier<Set<int>>({});

  int get _visible => SettingsStore.instance.visibleWhites.value;
  double get _maxStart => (_whites.length - _visible).toDouble();

  @override
  void initState() {
    super.initState();
    _startF = _whites.indexOf(60).toDouble(); // bắt đầu từ C4
  }

  @override
  void didUpdateWidget(covariant PianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu nốt cần gợi ý nằm ngoài vùng nhìn thấy thì trượt tới đó.
    if (widget.highlight.isEmpty) return;
    final idx = _whiteIndexOf(widget.highlight.first);
    if (idx < 0) return;
    final visible = _visible;
    if (idx < _startF || idx >= _startF + visible) {
      _startF = (idx - visible / 2).clamp(0.0, _maxStart).toDouble();
    }
  }

  @override
  void dispose() {
    _pressed.dispose();
    super.dispose();
  }

  void _setStart(double v) {
    setState(() => _startF = v.clamp(0.0, _maxStart).toDouble());
  }

  int _whiteIndexOf(int midi) {
    final w = _whiteSemitones.contains(midi % 12) ? midi : midi - 1;
    return _whites.indexOf(w);
  }

  int? _noteAt(Offset p, double whiteW, double blackW, double blackH) {
    if (p.dy < blackH) {
      for (final b in _blacks) {
        final left = (b.leftWhite - _startF + 1) * whiteW - blackW / 2;
        if (p.dx >= left && p.dx <= left + blackW) return b.midi;
      }
    }
    final idx = (_startF + p.dx / whiteW).floor();
    if (idx < 0 || idx >= _whites.length) return null;
    return _whites[idx];
  }

  void _press(int midi) {
    _pressed.value = {..._pressed.value, midi};
    PianoAudio.instance.playNote(midi);
    widget.onNote(midi);
  }

  void _release(int midi) {
    _pressed.value = {..._pressed.value}..remove(midi);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppThemeController.instance.accent,
        SettingsStore.instance.visibleWhites,
        SettingsStore.instance.labelMode,
      ]),
      builder: (context, _) {
        final accent = AppThemeController.instance.accent.value;
        final visible = _visible;
        final mode = SettingsStore.instance.labelMode.value;
        // Nếu vừa đổi số phím hiển thị, giữ vị trí cuộn trong giới hạn mới.
        _startF = _startF.clamp(0.0, _maxStart).toDouble();

        return Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Quãng tám thấp hơn',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _setStart(_startF - _octaveStep),
                  ),
                  const _EdgeLabel('Thấp'),
                  Expanded(
                    child: _Overview(
                      whites: _whites,
                      start: _startF,
                      visible: visible,
                      accent: accent,
                      onChanged: _setStart,
                    ),
                  ),
                  const _EdgeLabel('Cao'),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Quãng tám cao hơn',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _setStart(_startF + _octaveStep),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final whiteW = width / visible;
                  final blackW = whiteW * 0.6;
                  final blackH = height * 0.62;

                  void down(PointerDownEvent e) {
                    final n = _noteAt(e.localPosition, whiteW, blackW, blackH);
                    if (n == null) return;
                    _pointerNote[e.pointer] = n;
                    _press(n);
                  }

                  void move(PointerMoveEvent e) {
                    final old = _pointerNote[e.pointer];
                    final n = _noteAt(e.localPosition, whiteW, blackW, blackH);
                    if (n == null || n == old) return;
                    if (old != null) _release(old);
                    _pointerNote[e.pointer] = n;
                    _press(n);
                  }

                  void up(PointerEvent e) {
                    final old = _pointerNote.remove(e.pointer);
                    if (old != null) _release(old);
                  }

                  return Listener(
                    onPointerDown: down,
                    onPointerMove: move,
                    onPointerUp: up,
                    onPointerCancel: up,
                    child: ValueListenableBuilder<Set<int>>(
                      valueListenable: _pressed,
                      builder: (context, pressed, _) {
                        return SizedBox.expand(
                          child: CustomPaint(
                            painter: _KeysPainter(
                              whites: _whites,
                              blacks: _blacks,
                              start: _startF,
                              visible: visible,
                              pressed: pressed,
                              highlight: widget.highlight,
                              wrong: widget.wrong,
                              labels: widget.labels,
                              labelMode: mode,
                              accent: accent,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Vẽ toàn bộ phím trong một lần vẽ. Nhanh hơn nhiều so với một widget cho mỗi phím.
class _KeysPainter extends CustomPainter {
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

  _KeysPainter({
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
      _drawKey(
        canvas,
        Rect.fromLTWH(left + 1, 0, whiteW - 2, size.height),
        _whiteColors(midi),
        black: false,
        radius: 10,
        label: labels[midi] ?? noteLabel(midi, labelMode),
        labelColor: Colors.black87,
        pill: labels[midi] == null && labelMode != NoteLabelMode.off
            ? octaveColor(midi)
            : null,
        fontSize: (whiteW * 0.26).clamp(8.0, 16.0).toDouble(),
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
    Rect rect,
    List<Color> colors, {
    required bool black,
    required double radius,
    String? label,
    required Color labelColor,
    required double fontSize,
    Color? pill,
  }) {
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );

    // Bóng đổ
    canvas.drawRRect(
      rrect.shift(Offset(0, black ? 5 : 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: black ? 0.7 : 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, black ? 4 : 2),
    );

    // Nền gradient
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    // Viền
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = black ? Colors.black : const Color(0xFFB0B0BC),
    );

    if (label != null) {
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
      final pos = Offset(
        rect.center.dx - tp.width / 2,
        rect.bottom - tp.height - 8,
      );
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
  }

  @override
  bool shouldRepaint(covariant _KeysPainter old) => true;
}

class _EdgeLabel extends StatelessWidget {
  final String text;
  const _EdgeLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: text == 'Thấp' ? TextAlign.left : TextAlign.right,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Thanh tổng quan: toàn bộ phím trắng thu nhỏ, nền chuyển từ xanh (thấp) sang cam (cao),
/// khung sáng là vùng đang hiển thị.
class _Overview extends StatelessWidget {
  final List<int> whites;
  final double start;
  final int visible;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _Overview({
    required this.whites,
    required this.start,
    required this.visible,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxWidth / whites.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onChanged(d.localPosition.dx / unit - visible / 2),
          onHorizontalDragUpdate: (d) => onChanged(start + d.delta.dx / unit),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B5BDB), Color(0xFF7B5EA7), Color(0xFFF08C3A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              for (int i = 0; i < whites.length; i++)
                Positioned(
                  left: i * unit + 0.5,
                  top: 6,
                  bottom: 6,
                  width: unit - 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Positioned(
                left: start * unit,
                top: 0,
                bottom: 0,
                width: visible * unit,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.25),
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
