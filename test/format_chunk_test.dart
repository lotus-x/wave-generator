import 'package:flutter_test/flutter_test.dart';
import 'package:wave_generator/src/format_chunk.dart';
import 'package:wave_generator/wave_generator.dart';

void main() {
  group('format chunk', () {
    test('sGroupId should be "fmt "', () {
      final sut = createSut();

      expect(sut.sGroupId, 'fmt ');
    });

    test('first bytes should be "fmt " big endian', () async {
      final sut = createSut();

      int count = 0;
      final expectedFirstBytes = [0x66, 0x6D, 0x74, 0x20];
      await for (final byte in sut.bytes()) {
        expect(
          byte,
          expectedFirstBytes[count],
          reason:
              "byte $count should be ${expectedFirstBytes[count]} but was $byte",
        );
        count += 1;
        if (count > 3) break;
      }
    });

    test('PCM data length should be 16 bytes', () {
      final sut = createSut();

      expect(sut.length, 16);
    });

    test('PCM data length bytes should be 16 little endian', () async {
      final sut = createSut();

      int count = -1;
      final expectedBytes = [0x10, 0x00, 0x00, 0x00]; // 16
      await for (final byte in sut.bytes()) {
        count++;
        if (count < 4) continue;
        if (count >= 8) break;

        expect(
          byte,
          expectedBytes[count - 4],
          reason:
              "byte $count should be ${expectedBytes[count - 4]} but was $byte",
        );
      }
      expect(
        count,
        greaterThanOrEqualTo(7),
        reason: "Not enough bytes returned",
      );
    });

    test('Audio format bytes should be 1 (PCM)', () async {
      final sut = createSut();

      const expectMinimumBytes = 10;
      // array of [index, byteValue]
      final expectedBytes = [
        [8, 0x01],
        [9, 0x00]
      ];

      int currentByte = 0;

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

    test('Num channels bytes should be 1', () async {
      final sut = createSut();

      const expectMinimumBytes = 12;
      // array of [index, byteValue]
      final expectedBytes = [
        [10, 0x01],
        [11, 0x00]
      ];

      int currentByte = 0;

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

    test('Num channels bytes should be correct', () async {
      final sut = createSut(channels: 300);

      const expectMinimumBytes = 12;
      // array of [index, byteValue]
      final expectedBytes = [
        [10, 0x2C],
        [11, 0x01]
      ];

      int currentByte = 0;

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

    test('default sample rate should be 44100', () async {
      final sut = createSut();

      const expectMinimumBytes = 16;
      // array of [index, byteValue]
      final expectedBytes = [
        [12, 0x44],
        [13, 0xAC],
        [14, 0x00],
        [15, 0x00]
      ];

      int currentByte = 0;

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
      'when sample rate is not default, sample rate bytes should be correct',
      () async {
        final sut = createSut(sampleRate: 196000);

        const expectMinimumBytes = 16;
        // array of [index, byteValue]
        final expectedBytes = [
          [12, 0xA0],
          [13, 0xFD],
          [14, 0x02],
          [15, 0x00]
        ];

        int currentByte = 0;

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
      },
    );

    test(
      'byte rate should be 4 byte little endian equal to sample rate * channels * bytes per sample',
      () async {
        final sut = createSut(
          channels: 2,
        ); //BitDepth.Depth16bit

        final expectedValue = (44100 * 2 * (16 / 8)).toInt();

        const expectMinimumBytes = 20;
        // array of [index, byteValue]
        final expectedBytes = [
          [16, 0x10],
          [17, 0xB1],
          [18, 0x02],
          [19, 0x00]
        ];

        int currentByte = 0;

        expect(
          sut.bytesPerSecond,
          expectedValue,
          reason: 'Byte rate is incorrect',
        );

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
      },
    );

    test(
      'Block align should be 2 bytes little endian equal to channels * bytes per sample, ie. frame size',
      () async {
        final sut = createSut(
          channels: 5,
        );

        final expectedValue = (5 * (8 / 8)).toInt();

        const expectMinimumBytes = 22;
        // array of [index, byteValue]
        final expectedBytes = [
          [20, 0x05],
          [21, 0x00]
        ];

        int currentByte = 0;

        expect(sut.blockAlign, expectedValue,
            reason: 'Block align is incorrect');

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
      },
    );

    test('bits per sample should be set correctly', () async {
      final sut = createSut(
        channels: 2,
      ); //BitDepth.Depth16bit

      const expectedValue = 16;

      const expectMinimumBytes = 24;
      // array of [index, byteValue]
      final expectedBytes = [
        [22, 0x10],
        [23, 0x00]
      ];

      int currentByte = 0;

      expect(
        sut.bitDepth,
        expectedValue,
        reason: 'Bits per sample is incorrect',
      );

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

FormatChunk createSut({
  int channels = 1,
  int sampleRate = 44100,
  BitDepth depth = BitDepth.depth8bit,
}) //BitDepth.Depth16bit
{
  return FormatChunk(channels, sampleRate, depth);
}
