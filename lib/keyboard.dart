import 'dart:math';

import 'package:flutter/material.dart';

import 'audio.dart';

/// Bàn phím 2 quãng tám từ C4 (14 phím trắng), lấp đầy vùng được cấp.
class PianoKeyboard extends StatefulWidget {
  /// Gọi mỗi khi người chơi chạm vào một nốt mới.
  final void Function(int midi) onNote;

  /// Các nốt cần tô xanh lá để gợi ý.
  final Set<int> highlight;

  /// Nốt vừa bấm sai, tô đỏ thoáng qua.
  final int? wrong;

  const PianoKeyboard({
    super.key,
    required this.onNote,
    this.highlight = const {},
    this.wrong,
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

  Color _keyColor(int midi, Color base, Color highlightColor) {
    if (widget.wrong == midi) return const Color(0xFFF28B82);
    if (_pressed.contains(midi)) return const Color(0xFFBFD8FF);
    if (widget.highlight.contains(midi)) return highlightColor;
    return base;
  }

  @override
  Widget build(BuildContext context) {
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
                  left: i * whiteW,
                  top: 0,
                  width: whiteW,
                  height: height,
                  child: _key(
                    color: _keyColor(
                      _whiteNotes[i],
                      const Color(0xFFF7F7F5),
                      const Color(0xFFA8E6A1),
                    ),
                    borderColor: const Color(0xFF9A9A9A),
                  ),
                ),
              for (final b in _blackNotes)
                Positioned(
                  left: (b.leftWhite + 1) * whiteW - blackW / 2,
                  top: 0,
                  width: blackW,
                  height: blackH,
                  child: _key(
                    color: _keyColor(
                      b.midi,
                      const Color(0xFF1B1B1F),
                      const Color(0xFF2E7D32),
                    ),
                    borderColor: Colors.black,
                    radius: 4,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _key({
    required Color color,
    required Color borderColor,
    double radius = 6,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
    );
  }
}
