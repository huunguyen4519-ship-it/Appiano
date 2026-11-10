import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/audio.dart';
import '../../core/settings_store.dart';
import '../../core/theme.dart';
import '../../widgets/glass_box.dart';
import 'keyboard_overview.dart';
import 'keys_painter.dart';

const int _lowMidi = 36; // C2
const int _highMidi = 96; // C7
const int _octaveStep = 7;
const int _startMidi = 60; // C4, vị trí bắt đầu
const Set<int> _whiteSemitones = {0, 2, 4, 5, 7, 9, 11};

/// Bàn phím trượt qua nhiều quãng tám, có thanh tổng quan kính phía trên.
/// Đây là widget duy nhất xử lý chạm phím, nên mọi màn hình dùng chung một cách chạm.
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

class _PianoKeyboardState extends State<PianoKeyboard>
    with SingleTickerProviderStateMixin {
  late final List<int> _whites = [
    for (int m = _lowMidi; m <= _highMidi; m++)
      if (_whiteSemitones.contains(m % 12)) m,
  ];

  late final List<({int midi, int leftWhite})> _blacks = [
    for (int m = _lowMidi; m <= _highMidi; m++)
      if (!_whiteSemitones.contains(m % 12))
        (midi: m, leftWhite: _whites.indexOf(m - 1)),
  ];

  // Vị trí cuộn tính theo phím trắng, có thể là số lẻ để trượt mượt.
  // Dùng ValueNotifier để chỉ phần thanh tổng quan và phím được vẽ lại, không dựng lại cả màn.
  final ValueNotifier<double> _startF = ValueNotifier<double>(0);

  // Hoạt ảnh nhảy tới vị trí mới khi bấm mũi tên hoặc chạm vào thanh tổng quan.
  late final AnimationController _scroll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(_onScrollTick);
  double _scrollFrom = 0;
  double _scrollTo = 0;

  final Map<int, int> _pointerNote = {};

  // Mã âm thanh của từng nốt đang giữ, để tắt đúng nốt khi nhấc tay.
  final Map<int, int> _noteTokens = {};

  // Trạng thái phím đang bấm nằm riêng, để chỉ phần phím được vẽ lại khi bấm.
  final ValueNotifier<Set<int>> _pressed = ValueNotifier<Set<int>>({});

  int get _visible => SettingsStore.instance.visibleWhites.value;
  double get _maxStart => (_whites.length - _visible).toDouble();
  double _clamp(double v) => v.clamp(0.0, _maxStart).toDouble();
  double get _start => _clamp(_startF.value);

  @override
  void initState() {
    super.initState();
    _startF.value = _whites.indexOf(_startMidi).toDouble();
  }

  @override
  void didUpdateWidget(covariant PianoKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu nốt cần gợi ý nằm ngoài vùng nhìn thấy thì trượt tới đó.
    if (widget.highlight.isEmpty) return;
    final idx = _whiteIndexOf(widget.highlight.first);
    if (idx < 0) return;
    final visible = _visible;
    if (idx < _start || idx >= _start + visible) {
      _animateTo(idx - visible / 2);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _startF.dispose();
    for (final t in _noteTokens.values) {
      PianoAudio.instance.noteOff(t);
    }
    _pressed.dispose();
    super.dispose();
  }

  void _onScrollTick() {
    final t = Curves.easeOutCubic.transform(_scroll.value);
    _startF.value = _clamp(_scrollFrom + (_scrollTo - _scrollFrom) * t);
  }

  /// Trượt êm tới vị trí đích (dùng cho mũi tên và chạm).
  void _animateTo(double target) {
    _scrollFrom = _start;
    _scrollTo = _clamp(target);
    _scroll.forward(from: 0);
  }

  /// Khung bám theo ngón tay khi kéo. Hủy hoạt ảnh đang chạy để không bị giật.
  void _dragTo(double target) {
    _scroll.stop();
    _startF.value = _clamp(target);
  }

  int _whiteIndexOf(int midi) {
    final w = _whiteSemitones.contains(midi % 12) ? midi : midi - 1;
    return _whites.indexOf(w);
  }

  int? _noteAt(Offset p, double whiteW, double blackW, double blackH, double start) {
    if (p.dy < blackH) {
      for (final b in _blacks) {
        final left = (b.leftWhite - start + 1) * whiteW - blackW / 2;
        if (p.dx >= left && p.dx <= left + blackW) return b.midi;
      }
    }
    final idx = (start + p.dx / whiteW).floor();
    if (idx < 0 || idx >= _whites.length) return null;
    return _whites[idx];
  }

  void _press(int midi) {
    _pressed.value = {..._pressed.value, midi};
    _noteTokens[midi] = PianoAudio.instance.noteOn(midi);
    AppFeedback.key();
    widget.onNote(midi);
  }

  void _release(int midi) {
    _pressed.value = {..._pressed.value}..remove(midi);
    final token = _noteTokens.remove(midi);
    if (token != null) PianoAudio.instance.noteOff(token);
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

        return Column(
          children: [
            // Thanh tổng quan cùng lề với thanh tiêu đề phía trên (10 px mỗi bên).
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
              child: GlassBox(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Quãng tám thấp hơn',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _animateTo(_start - _octaveStep),
                      ),
                      const EdgeLabel('Thấp'),
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _startF,
                          builder: (context, value, _) => KeyboardOverview(
                            whites: _whites,
                            start: _clamp(value),
                            visible: visible,
                            accent: accent,
                            onTap: (pos) => _animateTo(pos - visible / 2),
                            onDrag: _dragTo,
                          ),
                        ),
                      ),
                      const EdgeLabel('Cao'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Quãng tám cao hơn',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _animateTo(_start + _octaveStep),
                      ),
                    ],
                  ),
                ),
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
                    final n = _noteAt(e.localPosition, whiteW, blackW, blackH, _start);
                    if (n == null) return;
                    _pointerNote[e.pointer] = n;
                    _press(n);
                  }

                  void move(PointerMoveEvent e) {
                    final old = _pointerNote[e.pointer];
                    final n = _noteAt(e.localPosition, whiteW, blackW, blackH, _start);
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
                    child: ValueListenableBuilder<double>(
                      valueListenable: _startF,
                      builder: (context, value, _) => ValueListenableBuilder<Set<int>>(
                        valueListenable: _pressed,
                        builder: (context, pressed, _) => SizedBox.expand(
                          child: CustomPaint(
                            painter: KeysPainter(
                              whites: _whites,
                              blacks: _blacks,
                              start: _clamp(value),
                              visible: visible,
                              pressed: pressed,
                              highlight: widget.highlight,
                              wrong: widget.wrong,
                              labels: widget.labels,
                              labelMode: mode,
                              accent: accent,
                            ),
                          ),
                        ),
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
}
