import 'package:flutter/material.dart';

import 'audio.dart';
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

  /// Chữ ghi trên phím, ví dụ số ngón tay.
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
const int visibleWhites = 14; // 2 quãng tám hiển thị cùng lúc
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
  final Set<int> _pressed = {};

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
    if (idx < _startF || idx >= _startF + visibleWhites) {
      _startF = (idx - visibleWhites / 2).clamp(0.0, _maxStart).toDouble();
    }
  }

  double get _maxStart => (_whites.length - visibleWhites).toDouble();

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
    setState(() => _pressed.add(midi));
    PianoAudio.instance.playNote(midi);
    widget.onNote(midi);
  }

  void _release(int midi) {
    setState(() => _pressed.remove(midi));
  }

  List<Color> _pressedColors(Color accent, bool black) {
    return black
        ? [Color.lerp(accent, Colors.white, 0.25)!, accent]
        : [Color.lerp(accent, Colors.white, 0.6)!, accent];
  }

  List<Color> _whiteColors(int midi, Color accent) {
    if (widget.wrong == midi) {
      return const [Color(0xFFFFB4AB), Color(0xFFE2574C)];
    }
    if (_pressed.contains(midi)) return _pressedColors(accent, false);
    if (widget.highlight.contains(midi)) {
      return const [Color(0xFFCFFAC4), Color(0xFF6BD16A)];
    }
    return const [Color(0xFFFFFFFF), Color(0xFFE6E6EE)];
  }

  List<Color> _blackColors(int midi, Color accent) {
    if (widget.wrong == midi) {
      return const [Color(0xFFFF8A80), Color(0xFFB71C1C)];
    }
    if (_pressed.contains(midi)) return _pressedColors(accent, true);
    if (widget.highlight.contains(midi)) {
      return const [Color(0xFF81C784), Color(0xFF1B5E20)];
    }
    return const [Color(0xFF3A3A46), Color(0xFF0A0A0E)];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppThemeController.instance.accent,
      builder: (context, accent, _) {
        return Column(
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Quãng tám thấp hơn',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _setStart(_startF - 7),
                  ),
                  Expanded(
                    child: _Overview(
                      whites: _whites,
                      start: _startF,
                      visible: visibleWhites,
                      accent: accent,
                      onChanged: _setStart,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Quãng tám cao hơn',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _setStart(_startF + 7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final whiteW = width / visibleWhites;
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          for (int i = 0; i < _whites.length; i++)
                            if (_inView(i - _startF, whiteW, width))
                              Positioned(
                                left: (i - _startF) * whiteW + 1,
                                top: 0,
                                width: whiteW - 2,
                                height: height,
                                child: _key(
                                  colors: _whiteColors(_whites[i], accent),
                                  black: false,
                                  radius: 10,
                                  label: widget.labels[_whites[i]],
                                  labelColor: Colors.black87,
                                ),
                              ),
                          for (final b in _blacks)
                            if (_inView(b.leftWhite - _startF, whiteW, width))
                              Positioned(
                                left: (b.leftWhite - _startF + 1) * whiteW -
                                    blackW / 2,
                                top: 0,
                                width: blackW,
                                height: blackH,
                                child: _key(
                                  colors: _blackColors(b.midi, accent),
                                  black: true,
                                  radius: 6,
                                  label: widget.labels[b.midi],
                                  labelColor: Colors.white,
                                ),
                              ),
                        ],
                      ),
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

  /// Phím có nằm trong hoặc sát vùng nhìn thấy không (tính theo đơn vị phím trắng).
  bool _inView(double unitsFromLeft, double whiteW, double width) {
    final left = unitsFromLeft * whiteW;
    return left > -whiteW && left < width;
  }

  Widget _key({
    required List<Color> colors,
    required bool black,
    required double radius,
    String? label,
    required Color labelColor,
  }) {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        border: Border.all(
          color: black ? Colors.black : const Color(0xFFB0B0BC),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: black ? 0.7 : 0.3),
            blurRadius: black ? 8 : 4,
            offset: Offset(0, black ? 5 : 2),
          ),
        ],
      ),
      child: label == null
          ? null
          : Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
    );
  }
}

/// Thanh tổng quan: toàn bộ phím trắng thu nhỏ, khung sáng là vùng đang hiển thị.
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
                    color: Colors.black.withValues(alpha: 0.35),
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
