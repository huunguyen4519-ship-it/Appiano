import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Nốt gốc của mẫu tổng hợp dự phòng (C4 = 60).
const int sampleBaseNote = 60;

/// Các nốt có mẫu thật trong assets/piano: A0, C1-C8 và mỗi quãng ba (C, D#, F#, A).
/// Mẫu lấy từ Salamander Grand Piano (CC BY 3.0, Alexander Holm).
/// Khoảng cách giữa hai mẫu liền nhau là quãng ba, nên đổi cao độ tối đa 1,5 nửa cung.
final List<int> _sampleMidis = [
  21, // A0
  for (int octave = 1; octave <= 7; octave++)
    for (final pc in _sampledPitchClasses) (octave + 1) * 12 + pc,
  108, // C8
];

const List<int> _sampledPitchClasses = [0, 3, 6, 9]; // C, D#, F#, A

const Map<int, String> _pitchClassNames = {0: 'C', 3: 'Ds', 6: 'Fs', 9: 'A'};

String _samplePath(int midi) {
  final name = _pitchClassNames[midi % 12]!;
  return 'assets/piano/$name${midi ~/ 12 - 1}.ogg';
}

/// Thời gian mờ dần sau khi thả phím.
/// Bấm nhanh rồi thả thì nốt tắt sớm; giữ phím thì nốt ngân cho tới khi thả.
const Duration _releaseFade = Duration(milliseconds: 300);

/// Một nốt đang phát, gắn với một lần nhấn phím.
class _Voice {
  SoundHandle? handle;
  bool released = false;
}

/// Âm thanh duy nhất của app: piano và các âm giao diện.
/// Mọi tầng khác chỉ gọi [noteOn], [noteOff] hoặc [playUi], không đụng vào thư viện âm thanh.
class PianoAudio {
  PianoAudio._();
  static final PianoAudio instance = PianoAudio._();

  static const _uiNames = ['click', 'correct', 'wrong', 'done'];

  /// Mẫu piano thật, khóa là số MIDI của mẫu.
  final Map<int, AudioSource> _samples = {};

  /// Mẫu tổng hợp dự phòng, chỉ dùng khi không nạp được mẫu thật nào.
  AudioSource? _fallback;

  final Map<String, AudioSource> _ui = {};

  final Map<int, _Voice> _voices = {};
  int _nextId = 0;

  Future<void> load() async {
    await SoLoud.instance.init();
    for (final midi in _sampleMidis) {
      try {
        _samples[midi] = await SoLoud.instance.loadAsset(_samplePath(midi));
      } catch (_) {
        // Thiếu một mẫu thì nốt đó dùng mẫu gần nhất, không làm app lỗi.
      }
    }
    try {
      _fallback = await SoLoud.instance.loadAsset('assets/piano_c4.wav');
    } catch (_) {}
    for (final name in _uiNames) {
      try {
        _ui[name] = await SoLoud.instance.loadAsset('assets/ui/$name.wav');
      } catch (_) {
        // Thiếu âm giao diện thì bỏ qua, không làm app lỗi.
      }
    }
  }

  int? _nearestLoaded(int midi) {
    int? best;
    for (final s in _samples.keys) {
      if (best == null || (s - midi).abs() < (best - midi).abs()) best = s;
    }
    return best;
  }

  /// Bắt đầu một nốt khi chạm xuống. Trả về mã để gọi [noteOff] khi nhấc tay.
  int noteOn(int midi) {
    final id = ++_nextId;
    final voice = _Voice();
    _voices[id] = voice;

    final near = _nearestLoaded(midi);
    final AudioSource? source = near != null ? _samples[near] : _fallback;
    if (source == null) return id;
    final base = near ?? sampleBaseNote;
    final speed = pow(2, (midi - base) / 12).toDouble();

    SoLoud.instance.play(source).then((handle) {
      voice.handle = handle;
      SoLoud.instance.setRelativePlaySpeed(handle, speed);
      // Nếu tay đã nhấc trước khi âm bắt đầu phát thì tắt luôn.
      if (voice.released) _fadeAndStop(handle);
    });
    return id;
  }

  /// Nhấc tay khỏi nốt: nốt mờ dần rồi tắt.
  void noteOff(int id) {
    final voice = _voices.remove(id);
    if (voice == null) return;
    voice.released = true;
    final handle = voice.handle;
    if (handle != null) _fadeAndStop(handle);
  }

  void _fadeAndStop(SoundHandle handle) {
    SoLoud.instance.fadeVolume(handle, 0, _releaseFade);
    Future<void>.delayed(_releaseFade, () => SoLoud.instance.stop(handle));
  }

  /// Phát âm giao diện theo tên: click, correct, wrong, done.
  void playUi(String name) {
    final source = _ui[name];
    if (source == null) return;
    SoLoud.instance.play(source);
  }
}
