import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_generator/wave_generator.dart';

void main() {
  test('single-tone', () async {
    final generator = WaveGenerator(
      /* sample rate */ 44100,
      BitDepth.depth8bit,
    );

    final note = Note(
      /* frequency */ 220,
      /* msDuration */ 3000,
      /* waveform */ Waveform.triangle,
      /* volume */ 0.5,
    );

    final file = File('test_out.wav');

    final bytes = <int>[];
    await for (final byte in generator.generate(note)) {
      bytes.add(byte);
    }

    file.writeAsBytes(bytes, mode: FileMode.append);
  });

  test('multi-tones', () async {
    final generator = WaveGenerator(44100, BitDepth.depth8bit);

    const baseTime = 100;
    const freq = 440.0;

    const dotDuration = baseTime;
    const dashDuration = baseTime * 3;
    const symbolGap = baseTime;
    const letterGap = baseTime * 3;

    final interSymbolSilence = Note(freq, symbolGap, Waveform.sine, 0.0);
    final interLetterSilence = Note(freq, letterGap, Waveform.sine, 0.0);
    final dit = Note(freq, dotDuration, Waveform.sine, 0.7);
    final dah = Note(freq, dashDuration, Waveform.sine, 0.7);

    final notes = [
      dit,
      interSymbolSilence,
      dit,
      interSymbolSilence,
      dit,
      interLetterSilence,
      dah,
      interSymbolSilence,
      dah,
      interSymbolSilence,
      dah,
      interLetterSilence,
      dit,
      interSymbolSilence,
      dit,
      interSymbolSilence,
      dit,
      interLetterSilence,
    ];

    final file = File('s-o-s.wav');

    final List<int> bytes = <int>[];
    await for (final byte in generator.generateSequence(notes)) {
      bytes.add(byte);
    }

    file.writeAsBytes(bytes, mode: FileMode.append);
  });
}
