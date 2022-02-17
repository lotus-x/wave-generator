// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';
import 'dart:typed_data';

class ByteHelpers {
  static Uint8List toBytes(String str) {
    const encoder = AsciiEncoder();
    return encoder.convert(str);
  }
}
