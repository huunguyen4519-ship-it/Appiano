import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:appiano/core/wav.dart';

void main() {
  test('ghi rồi đọc lại WAV giữ nguyên mẫu và tần số', () {
    final samples = Int16List.fromList([0, 1000, -1000, 32767, -32768]);
    final bytes = Wav(samples, 44100).encode();
    final back = Wav.decode(bytes);

    expect(back.sampleRate, 44100);
    expect(back.samples, samples);
  });

  test('từ chối file không phải WAV', () {
    final junk = Uint8List.fromList(List.filled(64, 7));
    expect(() => Wav.decode(junk), throwsFormatException);
  });
}
