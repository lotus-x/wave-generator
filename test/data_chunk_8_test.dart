import 'package:flutter_test/flutter_test.dart';
import 'package:wave_generator/src/chunk.dart';
import 'package:wave_generator/src/data_chunk8.dart';
import 'package:wave_generator/src/format_chunk.dart';

import 'package:wave_generator/wave_generator.dart';

void main() {
  group('8 bit data chunk', () {
    test('first bytes should be chunk Id "data" big endian', () async {
      final sut = createSut();

      const expectedValue = 'data';

      const expectMinimumBytes = 4;
      // array of [index, byteValue]
      final expectedBytes = [
        [00, 0x64],
        [01, 0x61],
        [02, 0x74],
        [03, 0x61]
      ];

      int currentByte = 0;

      expect(sut.sGroupId, expectedValue, reason: 'block id is incorrect');

      await for (final byte in sut.bytes()) {
        for (final expectedByte in expectedBytes) {
          if (currentByte == expectedByte[0]) {
            expect(
              byte,
              expectedByte[1],
              reason:
                  'Byte at index $currentByte incorrect. $byte instead of ${expectedByte[1]}',
            );
          }
        }

        currentByte++;
      }

      expect(
        currentByte,
        greaterThanOrEqualTo(expectMinimumBytes),
        reason: 'Not enough bytes returned',
      );
    });

    test(
        'data length bytes should be inferred from format and combined note durations',
        () async {
      const sampleRate = 44100;
      const bytesPerSample = 1;
      const channels = 1;
      const millisecondsDuration = 100;

      // = total samples * bytes per sample
      // = duration * samples per sec * bytes per sample
      final expectedDataLengthBytes =
          (sampleRate * (millisecondsDuration / 1000)).toInt() *
              channels *
              bytesPerSample;

      final format = FormatChunk(channels, sampleRate, BitDepth.depth8bit);
      final notes = [Note.a4(millisecondsDuration, 1)];
      final sut = createSut(format: format, notes: notes);

      final expectedValue = expectedDataLengthBytes;

      const expectMinimumBytes = 8;
      // array of [index, byteValue]
      final expectedBytes = [
        [04, 0x3A],
        [05, 0x11],
        [06, 0x00],
        [07, 0x00]
      ];

      int currentByte = 0;

      expect(sut.length, expectedValue, reason: 'block id is incorrect');

      await for (final byte in sut.bytes()) {
        for (final expectedByte in expectedBytes) {
          if (currentByte == expectedByte[0]) {
            expect(
              byte,
              expectedByte[1],
              reason:
                  'Byte at index $currentByte incorrect. $byte instead of ${expectedByte[1]}',
            );
          }
        }

        currentByte++;
      }

      expect(
        currentByte,
        greaterThanOrEqualTo(expectMinimumBytes),
        reason: 'Not enough bytes returned',
      );
    });
  });
}

DataChunk createSut({
  FormatChunk? format,
  List<Note>? notes,
}) {
  FormatChunk f;
  List<Note> n;

  f = format ?? FormatChunk(1, 44100, BitDepth.depth8bit);
  n = notes ?? [Note.a4(100, 1)];

  return DataChunk8(f, n);
}
