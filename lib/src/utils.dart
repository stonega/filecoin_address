// ignore_for_file: constant_identifier_names

import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:hashlib/hashlib.dart';

Uint8List getChecksumForPayload(Uint8List payload) {
  final blake2b = Blake2b(4);
  final sink = blake2b.createSink();
  sink.add(payload);
  return sink.digest().buffer.asUint8List();
}

bool validateNetworkPrefix(String networkPrefix) {
  return ['f', 't'].contains(networkPrefix);
}

Uint8List hexToUint8List(String hexString) {
  final hexString0 =
      hexString.startsWith('0x') ? hexString.substring(2) : hexString;
  final hash = List<int>.generate(hexString0.length ~/ 2,
      (i) => int.parse(hexString0.substring(i * 2, i * 2 + 2), radix: 16));
  return Uint8List.fromList(hash);
}

String listToHex(List<int> bytes) {
  StringBuffer buffer = StringBuffer();
  for (int part in bytes) {
    if (part & 0xff != part) {
      throw FormatException("Non-byte integer detected");
    }
    buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return buffer.toString();
}

String base32Encode(Uint8List input) {
  var encoded = base32.encode(input);
  while (encoded.endsWith('=')) {
    encoded = encoded.substring(0, encoded.length - 1);
  }
  return encoded;
}
