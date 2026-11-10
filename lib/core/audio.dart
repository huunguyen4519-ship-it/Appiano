import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Nốt gốc của mẫu piano (C4 = 60).
const int sampleBaseNote = 60;

/// Âm thanh duy nhất của app: piano và các âm giao diện.
/// Mọi tầng khác chỉ gọi [playNote] hoặc [playUi], không đụng vào thư viện âm thanh.
class PianoAudio {
  PianoAudio._();
  static final PianoAudio instance = PianoAudio._();

  static const _uiNames = ['click', 'correct', 'wrong', 'done'];

  AudioSource? _piano;
  final Map<String, AudioSource> _ui = {};

  Future<void> load() async {
    await SoLoud.instance.init();
    _piano = await SoLoud.instance.loadAsset('assets/piano_c4.wav');
    for (final name in _uiNames) {
      try {
        _ui[name] = await SoLoud.instance.loadAsset('assets/ui/$name.wav');
      } catch (_) {
        // Thiếu âm giao diện thì bỏ qua, không làm app lỗi.
      }
    }
  }

  /// Phát một nốt piano. Đổi tốc độ mẫu C4 để ra cao độ mong muốn.
  void playNote(int midi) {
    final source = _piano;
    if (source == null) return;
    final speed = pow(2, (midi - sampleBaseNote) / 12).toDouble();
    SoLoud.instance.play(source).then((handle) {
      SoLoud.instance.setRelativePlaySpeed(handle, speed);
    });
  }

  /// Phát âm giao diện theo tên: click, correct, wrong, done.
  void playUi(String name) {
    final source = _ui[name];
    if (source == null) return;
    SoLoud.instance.play(source);
  }
}
