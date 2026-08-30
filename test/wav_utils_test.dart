import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_studio/core/utils/wav_utils.dart';
import 'dart:typed_data';

void main() {
  test('WavUtils wraps PCM bytes with a valid RIFF/WAVE header', () {
    final pcm = Uint8List.fromList(List<int>.filled(100, 1));
    final wav = WavUtils.pcm16ToWav(pcm, sampleRate: 24000, channels: 1);

    // "RIFF" ... "WAVE" ... "data"
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(wav.length, 44 + pcm.length);
  });

  testWidgets('MaterialApp shell builds without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Voice Studio'))));
    expect(find.text('Voice Studio'), findsOneWidget);
  });
}
