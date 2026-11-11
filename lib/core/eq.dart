import 'dart:math' as math;
import 'dart:typed_data';

/// Bộ chỉnh âm (EQ) 5 dải cho mẫu âm thanh piano mono.
/// Dùng công thức biquad của Robert Bristow-Johnson (Audio EQ Cookbook).
class PianoEq {
  /// Tần số lấy mẫu cố định.
  static const double sampleRate = 44100.0;

  /// Tần số trung tâm của 5 dải (Hz).
  static const List<double> bandFrequencies = [60.0, 250.0, 1000.0, 4000.0, 12000.0];

  /// Q của các dải peaking.
  static const double peakingQ = 1.0;

  /// Giới hạn dB cho mỗi dải.
  static const double minGainDb = -12.0;
  static const double maxGainDb = 12.0;

  static const int bandCount = 5;

  /// Áp dụng EQ lên [input] (mono, 44100 Hz) với 5 giá trị [gainsDb].
  /// Trả về Float32List mới cùng độ dài. Trạng thái bộ lọc luôn được
  /// reset về 0 ở mỗi lần gọi.
  static Float32List process(Float32List input, List<double> gainsDb) {
    if (gainsDb.length != bandCount) {
      throw ArgumentError('Cần đúng $bandCount giá trị dB, nhận ${gainsDb.length}.');
    }
    var allZero = true;
    for (final g in gainsDb) {
      if (g.isNaN || g < minGainDb || g > maxGainDb) {
        throw ArgumentError('Giá trị dB phải nằm trong [$minGainDb, $maxGainDb]: $g');
      }
      if (g != 0.0) allZero = false;
    }

    // Tất cả dB = 0: trả về bản sao y hệt đầu vào.
    if (allZero) return Float32List.fromList(input);

    // Hệ số đã chuẩn hóa theo a0: mỗi dải 5 số [b0, b1, b2, a1, a2].
    final coeffs = Float64List(bandCount * 5);
    for (var band = 0; band < bandCount; band++) {
      _computeCoefficients(band, gainsDb[band], coeffs, band * 5);
    }

    // Trạng thái mỗi dải 4 số [x1, x2, y1, y2], khởi tạo 0 (reset).
    final state = Float64List(bandCount * 4);

    final length = input.length;
    final output = Float32List(length);

    // Vòng lặp chính: không cấp phát bộ nhớ mới.
    for (var n = 0; n < length; n++) {
      var sample = input[n].toDouble();
      for (var band = 0; band < bandCount; band++) {
        final c = band * 5;
        final s = band * 4;
        // Direct Form I.
        final y = coeffs[c] * sample +
            coeffs[c + 1] * state[s] +
            coeffs[c + 2] * state[s + 1] -
            coeffs[c + 3] * state[s + 2] -
            coeffs[c + 4] * state[s + 3];
        state[s + 1] = state[s];
        state[s] = sample;
        state[s + 3] = state[s + 2];
        state[s + 2] = y;
        sample = y;
      }
      // Giới hạn biên độ trong [-1, 1] để tránh vỡ tiếng.
      if (sample > 1.0) {
        sample = 1.0;
      } else if (sample < -1.0) {
        sample = -1.0;
      }
      output[n] = sample;
    }
    return output;
  }

  /// Tính hệ số biquad cho dải [band], ghi vào [out] tại vị trí [offset].
  static void _computeCoefficients(
      int band, double gainDb, Float64List out, int offset) {
    final a = math.pow(10.0, gainDb / 40.0).toDouble();
    final w0 = 2.0 * math.pi * bandFrequencies[band] / sampleRate;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);

    double b0, b1, b2, a0, a1, a2;

    if (band == 0) {
      // Low shelf với độ dốc S = 1.
      final alpha = sinW0 / 2.0 * math.sqrt(2.0);
      final k = 2.0 * math.sqrt(a) * alpha;
      b0 = a * ((a + 1) - (a - 1) * cosW0 + k);
      b1 = 2 * a * ((a - 1) - (a + 1) * cosW0);
      b2 = a * ((a + 1) - (a - 1) * cosW0 - k);
      a0 = (a + 1) + (a - 1) * cosW0 + k;
      a1 = -2 * ((a - 1) + (a + 1) * cosW0);
      a2 = (a + 1) + (a - 1) * cosW0 - k;
    } else if (band == bandCount - 1) {
      // High shelf với độ dốc S = 1.
      final alpha = sinW0 / 2.0 * math.sqrt(2.0);
      final k = 2.0 * math.sqrt(a) * alpha;
      b0 = a * ((a + 1) + (a - 1) * cosW0 + k);
      b1 = -2 * a * ((a - 1) + (a + 1) * cosW0);
      b2 = a * ((a + 1) + (a - 1) * cosW0 - k);
      a0 = (a + 1) - (a - 1) * cosW0 + k;
      a1 = 2 * ((a - 1) - (a + 1) * cosW0);
      a2 = (a + 1) - (a - 1) * cosW0 - k;
    } else {
      // Peaking EQ với Q = 1.0.
      final alpha = sinW0 / (2.0 * peakingQ);
      b0 = 1 + alpha * a;
      b1 = -2 * cosW0;
      b2 = 1 - alpha * a;
      a0 = 1 + alpha / a;
      a1 = -2 * cosW0;
      a2 = 1 - alpha / a;
    }

    // Chuẩn hóa theo a0.
    out[offset] = b0 / a0;
    out[offset + 1] = b1 / a0;
    out[offset + 2] = b2 / a0;
    out[offset + 3] = a1 / a0;
    out[offset + 4] = a2 / a0;
  }
}
