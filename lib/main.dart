import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

const int baseNote = 60; // C4
const String sampleAsset = 'assets/piano_c4.wav';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoLoud.instance.init();
  final source = await SoLoud.instance.loadAsset(sampleAsset);
  runApp(AppianoApp(source: source));
}

class AppianoApp extends StatelessWidget {
  final AudioSource source;
  const AppianoApp({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appiano',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF111114),
        body: SafeArea(
          child: Center(child: PianoKeyboard(source: source)),
        ),
      ),
    );
  }
}

class PianoKeyboard extends StatefulWidget {
  final AudioSource source;
  const PianoKeyboard({super.key, required this.source});

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  // Số phím trắng trong 1 quãng tám: C D E F G A B
  static const _whiteSemitones = [0, 2, 4, 5, 7, 9, 11];
  // Vị trí phím đen nằm sau các phím trắng có chỉ số này (C, D, F, G, A)
  static const _blackAfter = {0, 2, 5, 7, 9};

  // 2 quãng tám từ C4: 14 phím trắng
  final List<int> _whiteNotes = [
    for (int oct = 0; oct < 2; oct++)
      for (final s in _whiteSemitones) baseNote + 12 * oct + s,
  ];

  late final List<({int midi, int leftWhite})> _blackNotes = _buildBlackNotes();

  final Map<int, int> _pointerNote = {}; // pointerId -> midi
  final Set<int> _pressed = {};

  List<({int midi, int leftWhite})> _buildBlackNotes() {
    final result = <({int midi, int leftWhite})>[];
    for (int i = 0; i < _whiteNotes.length; i++) {
      final semitone = (_whiteNotes[i] - baseNote) % 12;
      if (_blackAfter.contains(semitone)) {
        result.add((midi: _whiteNotes[i] + 1, leftWhite: i));
      }
    }
    return result;
  }

  // Đổi tốc độ phát so với C4: mỗi nửa cung nhân với 2^(1/12)
  double _speedFor(int midi) => pow(2, (midi - baseNote) / 12).toDouble();

  Future<void> _play(int midi) async {
    setState(() => _pressed.add(midi));
    final handle = await SoLoud.instance.play(widget.source);
    SoLoud.instance.setRelativePlaySpeed(handle, _speedFor(midi));
  }

  void _release(int midi) {
    setState(() => _pressed.remove(midi));
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

  void _onDown(PointerDownEvent e, double whiteW, double blackW, double blackH) {
    final n = _noteAt(e.localPosition, whiteW, blackW, blackH);
    if (n == null) return;
    _pointerNote[e.pointer] = n;
    _play(n);
  }

  void _onMove(PointerMoveEvent e, double whiteW, double blackW, double blackH) {
    final old = _pointerNote[e.pointer];
    final n = _noteAt(e.localPosition, whiteW, blackW, blackH);
    if (n == null || n == old) return;
    if (old != null) _release(old);
    _pointerNote[e.pointer] = n;
    _play(n);
  }

  void _onUp(PointerEvent e) {
    final old = _pointerNote.remove(e.pointer);
    if (old != null) _release(old);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(constraints.maxWidth, 700.0);
        final height = width * 0.5;
        final whiteW = width / _whiteNotes.length;
        final blackW = whiteW * 0.6;
        final blackH = height * 0.62;

        return SizedBox(
          width: width,
          height: height,
          child: Listener(
            onPointerDown: (e) => _onDown(e, whiteW, blackW, blackH),
            onPointerMove: (e) => _onMove(e, whiteW, blackW, blackH),
            onPointerUp: _onUp,
            onPointerCancel: _onUp,
            child: Stack(
              children: [
                for (int i = 0; i < _whiteNotes.length; i++)
                  Positioned(
                    left: i * whiteW,
                    top: 0,
                    width: whiteW,
                    height: height,
                    child: _key(
                      color: _pressed.contains(_whiteNotes[i])
                          ? const Color(0xFFBFD8FF)
                          : const Color(0xFFF7F7F5),
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
                      color: _pressed.contains(b.midi)
                          ? const Color(0xFF4A6FA5)
                          : const Color(0xFF1B1B1F),
                      borderColor: Colors.black,
                      radius: 4,
                    ),
                  ),
              ],
            ),
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
