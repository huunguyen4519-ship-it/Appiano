import 'package:flutter/material.dart';

import 'audio.dart';
import 'ui.dart';

/// Bàn phím 2 quãng tám từ C4 (14 phím trắng), lấp đầy vùng được cấp.
class PianoKeyboard extends StatefulWidget {
  /// Gọi mỗi khi người chơi chạm vào một nốt mới.
  final void Function(int midi) onNote;

  /// Các nốt cần tô xanh lá để gợi ý.
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

class _PianoKeyboardState extends State<PianoKeyboard> {
  static const int _startNote = 60;
  static const _whiteSemitones = [0, 2, 4, 5, 7, 9, 11];
  static const _blackAfter = {0, 2, 5, 7, 9};

  final List<int> _whiteNotes = [
    for (int oct = 0; oct < 2; oct++)
      for (final s in _whiteSemitones) _startNote + 12 * oct + s,
  ];

  late final List<({int midi, int leftWhite})> _blackNotes = _buildBlackNotes();

  final Map<int, int> _pointerNote = {}; // pointerId -> midi
  final Set<int> _pressed = {};

  List<({int midi, int leftWhite})> _buildBlackNotes() {
    final result = <({int midi, int leftWhite})>[];
    for (int i = 0; i < _whiteNotes.length; i++) {
      final semitone = (_whiteNotes[i] - _startNote) % 12;
      if (_blackAfter.contains(semitone)) {
        result.add((midi: _whiteNotes[i] + 1, leftWhite: i));
      }
    }
    return result;
  }

  int? _noteAt(Offset p, double whiteW, double blackW, double blackH) {
    if (p.dy < blackH) {
      for (final b in _blackNotes) {
        final left = (b.leftWhite + 1) * whiteW - blackW / 2;
        if (p.dx >= left && p.dx <= left + blackW) return b.midi;
      }
    }
    final idx = (p.dx / whiteW).floor().clamp(0, _whiteNotes.length - 1);
    return _whiteNotes[idx];
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final whiteW = width / _whiteNotes.length;
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
              child: Stack(
                children: [
                  for (int i = 0; i < _whiteNotes.length; i++)
                    Positioned(
                      left: i * whiteW + 1,
                      top: 0,
                      width: whiteW - 2,
                      height: height,
                      child: _key(
                        colors: _whiteColors(_whiteNotes[i], accent),
                        black: false,
                        radius: 8,
                        label: widget.labels[_whiteNotes[i]],
                        labelColor: Colors.black87,
                      ),
                    ),
                  for (final b in _blackNotes)
                    Positioned(
                      left: (b.leftWhite + 1) * whiteW - blackW / 2,
                      top: 0,
                      width: blackW,
                      height: blackH,
                      child: _key(
                        colors: _blackColors(b.midi, accent),
                        black: true,
                        radius: 5,
                        label: widget.labels[b.midi],
                        labelColor: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
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
