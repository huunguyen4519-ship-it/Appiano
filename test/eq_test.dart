import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../lib/core/eq.dart';

/// Tạo sóng sin mono ở 44100 Hz.
Float32List makeSine(double freq, double amplitude, int length) {
  final data = Float32List(length);
  for (var i = 0; i < length; i++) {
    data[i] = amplitude * math.sin(2 * math.pi * freq * i / PianoEq.sampleRate);
  }
  return data;
}

/// Biên độ đỉnh, bỏ qua [skip] mẫu đầu để tránh phần quá độ.
double peak(Float32List data, {int skip = 0}) {
  var p = 0.0;
  for (var i = skip; i < data.length; i++) {
    final v = data[i].abs();
    if (v > p) p = v;
  }
  return p;
}

void main() {
  test('dB đều bằng 0 cho kết quả giống hệt đầu vào', () {
    final input = makeSine(440.0, 0.5, 4410);
    final output = PianoEq.process(input, [0, 0, 0, 0, 0]);

    expect(output.length, input.length);
    expect(identical(output, input), isFalse); // phải là bản sao
    for (var i = 0; i < input.length; i++) {
      expect(output[i], input[i]);
    }
  });

  test('sin 1 kHz với +6 dB ở dải 1 kHz có biên độ lớn hơn đầu vào', () {
    final input = makeSine(1000.0, 0.25, 44100);
    final output = PianoEq.process(input, [0, 0, 6, 0, 0]);

    final inPeak = peak(input, skip: 4410);
    final outPeak = peak(output, skip: 4410);

    expect(output.length, input.length);
    expect(outPeak, greaterThan(inPeak));
    // +6 dB ≈ gấp đôi biên độ.
    expect(outPeak / inPeak, closeTo(2.0, 0.1));
  });

  test('đầu ra luôn nằm trong [-1, 1]', () {
    final input = makeSine(1000.0, 0.9, 44100);
    final output = PianoEq.process(input, [12, 12, 12, 12, 12]);
    expect(peak(output), lessThanOrEqualTo(1.0));
  });

  test('ném lỗi khi dữ liệu dB không hợp lệ', () {
    final input = makeSine(1000.0, 0.5, 100);
    expect(() => PianoEq.process(input, [0, 0, 0]), throwsArgumentError);
    expect(() => PianoEq.process(input, [0, 0, 13, 0, 0]), throwsArgumentError);
  });
}
