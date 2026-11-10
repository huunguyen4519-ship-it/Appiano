import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Nốt gốc của mẫu âm thanh (C4 = 60).
const int sampleBaseNote = 60;

/// Phát âm piano bằng một mẫu duy nhất, đổi tốc độ để ra các nốt khác.
class PianoAudio {
  PianoAudio._();
  static final PianoAudio instance = PianoAudio._();

  AudioSource? _source;

  Future<void> load() async {
    await SoLoud.instance.init();
    _source = await SoLoud.instance.loadAsset('assets/piano_c4.wav');
  }

  void playNote(int midi) {
    final source = _source;
    if (source == null) return;
    final speed = pow(2, (midi - sampleBaseNote) / 12).toDouble();
    SoLoud.instance.play(source).then((handle) {
      SoLoud.instance.setRelativePlaySpeed(handle, speed);
    });
  }
}
