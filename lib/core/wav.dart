import 'dart:typed_data';

/// Đọc và ghi WAV PCM 16-bit mono. Chỉ hỗ trợ đúng định dạng app cần.
class Wav {
  final Int16List samples;
  final int sampleRate;

  const Wav(this.samples, this.sampleRate);

  /// Đọc WAV bằng cách duyệt các chunk, không giả định vị trí cố định.
  static Wav decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < 12 || _ascii(bytes, 0) != 'RIFF' || _ascii(bytes, 8) != 'WAVE') {
      throw const FormatException('Không phải file WAV.');
    }
    int? rate;
    int? channels;
    int? bits;
    int? dataStart;
    int? dataLength;
    var pos = 12;
    while (pos + 8 <= bytes.length) {
      final id = _ascii(bytes, pos);
      final size = data.getUint32(pos + 4, Endian.little);
      final body = pos + 8;
      if (id == 'fmt ') {
        channels = data.getUint16(body + 2, Endian.little);
        rate = data.getUint32(body + 4, Endian.little);
        bits = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataStart = body;
        dataLength = size.clamp(0, bytes.length - body);
      }
      // Chunk lẻ có một byte đệm.
      pos = body + size + (size.isOdd ? 1 : 0);
    }
    if (rate == null || channels == null || bits == null || dataStart == null) {
      throw const FormatException('WAV thiếu chunk fmt hoặc data.');
    }
    if (bits != 16 || channels != 1) {
      throw FormatException('Chỉ hỗ trợ WAV 16-bit mono, nhận $bits-bit, $channels kênh.');
    }
    final count = dataLength! ~/ 2;
    final samples = Int16List(count);
    for (var i = 0; i < count; i++) {
      samples[i] = data.getInt16(dataStart + i * 2, Endian.little);
    }
    return Wav(samples, rate);
  }

  /// Ghi thành bytes WAV 16-bit mono hoàn chỉnh.
  Uint8List encode() {
    final dataBytes = samples.length * 2;
    final out = ByteData(44 + dataBytes);
    void writeAscii(int offset, String s) {
      for (var i = 0; i < 4; i++) {
        out.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    out.setUint32(4, 36 + dataBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    out.setUint32(16, 16, Endian.little);
    out.setUint16(20, 1, Endian.little); // PCM
    out.setUint16(22, 1, Endian.little); // mono
    out.setUint32(24, sampleRate, Endian.little);
    out.setUint32(28, sampleRate * 2, Endian.little);
    out.setUint16(32, 2, Endian.little);
    out.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    out.setUint32(40, dataBytes, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      out.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return out.buffer.asUint8List();
  }

  static String _ascii(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));
}
