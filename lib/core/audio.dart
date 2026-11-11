import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'eq.dart';
import 'settings_store.dart';
import 'wav.dart';

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
  return 'assets/piano/$name${midi ~/ 12 - 1}.wav';
}

/// Việc lọc EQ cho cả bộ mẫu, chạy ở isolate để không làm giật giao diện.
class _EqJob {
  final Map<int, Int16List> pcm;
  final List<double> gains;
  const _EqJob(this.pcm, this.gains);
}

Map<int, Uint8List> _applyEqJob(_EqJob job) {
  final out = <int, Uint8List>{};
  final rate = PianoEq.sampleRate.toInt();
  for (final entry in job.pcm.entries) {
    final src = entry.value;
    final input = Float32List(src.length);
    for (var i = 0; i < src.length; i++) {
      input[i] = src[i] / 32768.0;
    }
    final eq = PianoEq.process(input, job.gains);
    final ints = Int16List(eq.length);
    for (var i = 0; i < eq.length; i++) {
      ints[i] = (eq[i] * 32767).round().clamp(-32768, 32767);
    }
    out[entry.key] = Wav(ints, rate).encode();
  }
  return out;
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

  /// Mẫu piano thật đã giải mã (chưa qua EQ), khóa là số MIDI.
  final Map<int, Int16List> _pcm = {};

  /// Mẫu piano đang phát, đã qua EQ, khóa là số MIDI.
  final Map<int, AudioSource> _samples = {};

  Timer? _eqDebounce;
  int _eqGen = 0;

  /// Mẫu tổng hợp dự phòng, chỉ dùng khi không nạp được mẫu thật nào.
  AudioSource? _fallback;

  final Map<String, AudioSource> _ui = {};

  final Map<int, _Voice> _voices = {};
  int _nextId = 0;

  Future<void> load() async {
    await SoLoud.instance.init();
    for (final midi in _sampleMidis) {
      try {
        final data = await rootBundle.load(_samplePath(midi));
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        _pcm[midi] = Wav.decode(bytes).samples;
      } catch (_) {
        // Thiếu một mẫu thì nốt đó dùng mẫu gần nhất, không làm app lỗi.
      }
    }
    await _rebuildSamples();
    for (final band in SettingsStore.instance.eqGains) {
      band.addListener(_onEqChanged);
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

  // Kéo thanh trượt liên tục thì chờ người dùng ngừng rồi mới lọc lại.
  void _onEqChanged() {
    _eqDebounce?.cancel();
    _eqDebounce = Timer(const Duration(milliseconds: 250), _rebuildSamples);
  }

  /// Lọc lại toàn bộ mẫu theo EQ hiện tại và nạp vào SoLoud.
  Future<void> _rebuildSamples() async {
    if (_pcm.isEmpty) return;
    final gen = ++_eqGen;
    final gains = [for (final band in SettingsStore.instance.eqGains) band.value];
    final wavs = await compute(_applyEqJob, _EqJob(_pcm, gains));
    // Có thay đổi mới hơn trong lúc đang lọc: bỏ kết quả cũ.
    if (gen != _eqGen) return;
    for (final entry in wavs.entries) {
      try {
        final next = await SoLoud.instance.loadMem(
          'piano_${entry.key}_$gen',
          entry.value,
        );
        final old = _samples[entry.key];
        _samples[entry.key] = next;
        if (old != null) SoLoud.instance.disposeSource(old);
      } catch (_) {
        // Lỗi một mẫu thì mẫu đó giữ bản cũ.
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
