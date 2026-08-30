import 'dart:typed_data';

/// Gemini's TTS response returns raw 16-bit PCM audio (mono, 24kHz)
/// with no container. Standard audio players need a WAV header, so we
/// wrap the PCM bytes ourselves instead of depending on native codec
/// plugins.
class WavUtils {
  WavUtils._();

  static Uint8List pcm16ToWav(
    Uint8List pcmBytes, {
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataLength = pcmBytes.length;
    final chunkSize = 36 + dataLength;

    final header = BytesBuilder();
    header.add(_ascii('RIFF'));
    header.add(_uint32le(chunkSize));
    header.add(_ascii('WAVE'));

    header.add(_ascii('fmt '));
    header.add(_uint32le(16)); // PCM fmt chunk size
    header.add(_uint16le(1)); // audio format = PCM
    header.add(_uint16le(channels));
    header.add(_uint32le(sampleRate));
    header.add(_uint32le(byteRate));
    header.add(_uint16le(blockAlign));
    header.add(_uint16le(bitsPerSample));

    header.add(_ascii('data'));
    header.add(_uint32le(dataLength));
    header.add(pcmBytes);

    return header.toBytes();
  }

  static Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);

  static Uint8List _uint32le(int value) {
    final b = ByteData(4);
    b.setUint32(0, value, Endian.little);
    return b.buffer.asUint8List();
  }

  static Uint8List _uint16le(int value) {
    final b = ByteData(2);
    b.setUint16(0, value, Endian.little);
    return b.buffer.asUint8List();
  }
}
