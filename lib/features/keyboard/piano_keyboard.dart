import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/audio.dart';
import '../../core/settings_store.dart';
import '../../core/theme.dart';
import 'keyboard_overview.dart';
import 'keyboard_palette.dart';
import 'keys_painter.dart';

const int _lowMidi = 36; // C2
const int _highMidi = 96; // C7
const int _octaveStep = 7;
const int _startMidi = 60; // C4, vị trí bắt đầu
const Set<int> _whiteSemitones = {0, 2, 4, 5, 7, 9, 11};

/// Bàn phím trượt qua nhiều quãng tám, có thanh tổng quan phía trên.
/// Widget này chỉ lo chạm và vẽ. Âm thanh đi qua [PianoAudio], phản hồi đi qua [AppFeedback],
/// và ký âm đọc từ [SettingsStore], nên đổi kiểu nào cũng không phải sửa bàn phím.
class PianoKeyboard extends StatefulWidget {
  /// Gọi mỗi khi người chơi chạm vào một nốt mới.
  final void Function(int midi) onNote;

  /// Các nốt cần tô gợi ý. Bàn phím tự trượt tới nốt đầu tiên.
  final Set<int> highlight;

  /// Nốt vừa bấm sai, tô đỏ thoáng qua.
  final int? wrong;

  /// Chữ ghi đè lên phím, ví dụ số ngón tay. Ưu tiên hơn ký âm chung.
  final Map<int, String> labels;

  /// Bảng màu của màn hình đang dùng.
  final KeyboardPalette palette;

  const PianoKeyboard({
    super.key,
    required this.onNote,
    this.highlight = const {},
    this.wrong,
    this.labels = const {},
    this.palette = defaultPalette,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

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

  final Map<int, int> _pointerNote = {};

  // Trạng thái phím đang bấm nằm riêng, để chỉ phần phím được vẽ lại khi bấm.
  final ValueNotifier<Set<int>> _pressed = ValueNotifier<Set<int>>({});

  int get _visible => SettingsStore.instance.visibleWhites.value;
  double get _maxStart => (_whites.length - _visible).toDouble();

  @override
  void initState() {
    super.initState();
    _startF = _whites.indexOf(_startMidi).toDouble();
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
    AppFeedback.key();
    widget.onNote(midi);
  }

  void _release(int midi) {
    _pressed.value = {..._pressed.value}..remove(midi);
  }

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppThemeController.instance.accent,
        store.visibleWhites,
        store.notation,
        store.labelsVisible,
      ]),
      builder: (context, _) {
        final palette = widget.palette;
        final themeAccent = AppThemeController.instance.accent.value;
        final accent = palette.accent ?? themeAccent;
        final visible = _visible;
        final notation =
            store.labelsVisible.value ? store.notation.value : null;
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
                  const EdgeLabel('Thấp'),
                  Expanded(
                    child: KeyboardOverview(
                      whites: _whites,
                      start: _startF,
                      visible: visible,
                      palette: palette,
                      accent: accent,
                      onChanged: _setStart,
                    ),
                  ),
                  const EdgeLabel('Cao'),
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
                            painter: KeysPainter(
                              whites: _whites,
                              blacks: _blacks,
                              start: _startF,
                              visible: visible,
                              pressed: pressed,
                              highlight: widget.highlight,
                              wrong: widget.wrong,
                              labels: widget.labels,
                              notation: notation,
                              palette: palette,
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
