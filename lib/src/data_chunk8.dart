import 'dart:math';
import 'dart:typed_data';

import 'package:wave_generator/src/byte_helpers.dart';
import 'package:wave_generator/src/chunk.dart';
import 'package:wave_generator/src/format_chunk.dart';
import 'package:wave_generator/src/generator_function.dart';
import 'package:wave_generator/wave_generator.dart';

class DataChunk8 implements DataChunk {
  final FormatChunk format;
  final List<Note> notes;

  final String _sGroupId = "data";

  // nb. Stored as unsigned bytes in the rage 0 to 255
  static const int min = 0;
  static const int max = 255;

  int clamp(int byte) {
    return byte.clamp(min, max);
  }

  DataChunk8(this.format, this.notes);

  @override
  Stream<int> bytes() async* {
    // sGroupId
    final groupIdBytes = ByteHelpers.toBytes(_sGroupId);
    final bytes = groupIdBytes.buffer.asByteData();

    for (int i = 0; i < 4; i++) {
      yield bytes.getUint8(i);
    }

    // length
    final byteData = ByteData(4);
    byteData.setUint32(0, length, Endian.little);
    for (int i = 0; i < 4; i++) {
      yield byteData.getUint8(i);
    }

    // Determine when one note ends and the next begins
    // Number of samples per note given by sampleRate * note duration
    // compare against step count to select the correct note
    int noteNumber = 0;
    int incrementNoteOnSample =
        (notes[noteNumber].msDuration * format.sampleRate) ~/ 1000;

    final int sampleMax = totalSamples;
    const amplify = (max + 1) / 2;
    for (int step = 0; step < sampleMax; step++) {
      if (incrementNoteOnSample == step) {
        noteNumber += 1;
        incrementNoteOnSample +=
            (notes[noteNumber].msDuration * format.sampleRate) ~/ 1000;
      }

      final theta = notes[noteNumber].frequency * (2 * pi) / format.sampleRate;
      final generator = GeneratorFunction.create(notes[noteNumber].waveform);

      final y = generator.generate(theta * step);
      final volume = amplify * notes[noteNumber].volume;
      final sample = (volume * y) + volume;
      final intSampleVal = sample.toInt();
      final sampleByte = clamp(intSampleVal);
      yield sampleByte;
    }

    // If the number of bytes is not word-aligned, ie. number of bytes is odd, we need to pad with additional zero bytes.
    // These zero bytes should not appear in the data chunk length header
    // but probably do get included for the length bytes in the file header
    if (length % 2 != 0) yield 0x00;
  }

  @override
  int get length {
    return totalSamples * format.blockAlign;
  }

  int get totalSamples {
    final secondsDuration = notes
            .map(
              (note) => note.msDuration,
            )
            .reduce(
              (a, b) => a + b,
            ) /
        1000;
    return (format.sampleRate * secondsDuration).toInt();
  }

  @override
  String get sGroupId => _sGroupId;

  @override
  int get bytesPadding => length.isEven ? 0 : 1;
}
