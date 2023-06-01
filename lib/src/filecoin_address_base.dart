// ignore_for_file: constant_identifier_names
import 'package:base32/base32.dart';
import 'dart:typed_data';
import './utils.dart';
import 'package:leb128/leb128.dart';

enum ProtocolIndicator { ID, SECP256K1, ACTOR, BLS, DELEGATED }

class Address {
  Uint8List payload;
  String networkPrefix;
  ProtocolIndicator protocol = ProtocolIndicator.SECP256K1;

  Address(this.networkPrefix, this.payload);

  static Address fromString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    // if (!validateNetworkPrefix(networkPrefix)) throw new InvalidNetwork()
    if (int.parse(protocolIndicator) != 1) throw Error();

    final decodedData = base32.decode(address.substring(2).toUpperCase());
    // final length = decodedData.length;
    final payload = decodedData.sublist(0, decodedData.length -4);
    // final checksum = decodedData.sublist(-4);

    final newAddress = Address(networkPrefix, payload);
    // if (newAddress.getChecksum().toString('hex') !== checksum.toString('hex')) throw new InvalidChecksumAddress()
    return newAddress;
  }

  Uint8List toBytes() {
    final protocol = Uint8List.fromList([0x1]);
    return Uint8List.fromList(protocol + payload);
  }
}

class FilEthAddress {
  late Uint8List payload;
  String networkPrefix = 'f';
  ProtocolIndicator protocolIndicator = ProtocolIndicator.DELEGATED;
  late Uint8List subAddress;
  final nameSpace = 10;
  final protocol = ProtocolIndicator.DELEGATED;

  FilEthAddress(Uint8List ethAddress) {
    subAddress = ethAddress;
    payload = toBytes().sublist(1);
  }

  Uint8List toBytes() {
    final namespaceBytes = Leb128.encodeUnsigned(nameSpace);
    final protocolBytes = Leb128.encodeUnsigned(4);

    return Uint8List.fromList(protocolBytes + namespaceBytes + subAddress);
  }

  @override
  String toString() {
    final checksum = getChecksum(toBytes());
    return '$networkPrefix${protocol.index}${nameSpace}f${base32Encode(Uint8List.fromList(subAddress + checksum)).toLowerCase()}';
  }

  static FilEthAddress fromString(String address) {
    final protocolIndicator = address[1];
    if (int.parse(protocolIndicator) != 4) throw Error();
    final dataEncoded = address.substring(address.indexOf('f', 2) + 1);
    final dataDecoded = base32.decode(dataEncoded.toUpperCase());
    final subAddress = dataDecoded.sublist(0, dataDecoded.length - 4);
    final newAddress = FilEthAddress(subAddress);
    return newAddress;
  }

  static FilEthAddress fromEthString(String address) {
    final protocolIndicator = address[1];

    // if (!validateNetworkPrefix(networkPrefix)) throw new InvalidNetwork()
    if (int.parse(protocolIndicator) != 1) throw Error();

    final decodedData = base32.decode(address.substring(2).toUpperCase());
    // final length = decodedData.length;
    final payload = decodedData.sublist(0, -4);
    // final checksum = decodedData.sublist(-4);

    final newAddress = FilEthAddress(payload);
    // if (newAddress.getChecksum().toString('hex') !== checksum.toString('hex')) throw new InvalidChecksumAddress()
    return newAddress;
  }

  String toEthHex([hexPrefix = true]) {
    return '${hexPrefix ? '0x' : ''}${subAddress.map((int a) => a.toRadixString(16).padLeft(2, '0')).join('')}';
  }
}
