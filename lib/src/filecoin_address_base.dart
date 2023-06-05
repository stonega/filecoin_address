// ignore_for_file: constant_identifier_names
import 'package:base32/base32.dart';
import 'dart:typed_data';
import './utils.dart';
import 'package:leb128/leb128.dart';

import 'constant.dart';
import 'error.dart';

enum ProtocolIndicator { ID, SECP256K1, ACTOR, BLS, DELEGATED }

class Address {
  late final Uint8List _payload;
  late final String _networkPrefix;
  ProtocolIndicator protocol = ProtocolIndicator.SECP256K1;

  String get networkPrefix => _networkPrefix;
  Uint8List get payload => _payload;

  Uint8List toBytes() {
    return Uint8List.fromList([protocol.index] + _payload);
  }

  Uint8List getChecksum() {
    return getChecksumForPayload(toBytes());
  }

  static Address fromString(String address) {
    final type = int.parse(address[1]);
    final protocol = ProtocolIndicator.values[type];
    switch (protocol) {
      case ProtocolIndicator.ID:
        return AddressId.fromAddressString(address);
      case ProtocolIndicator.ACTOR:
        return AddressActor.fromAddressString(address);
      case ProtocolIndicator.SECP256K1:
        return AddressSecp256k1.fromAddressString(address);
      case ProtocolIndicator.BLS:
        return AddressBls.fromAddressString(address);
      case ProtocolIndicator.DELEGATED:
        final addr = AddressDelegated.fromAddressString(address);
        if (Address.isFilEthAddress(addr)) {
          return FilEthAddress(addr.networkPrefix, addr.subAddress);
        }
        return addr;
      default:
        throw FilAddressError("Unknown protocol");
    }
  }

  static bool isAddressId(Address address) =>
      address.protocol == ProtocolIndicator.ID;

  static bool isAddressBls(Address address) =>
      address.protocol == ProtocolIndicator.BLS;

  static bool isAddressActor(Address address) =>
      address.protocol == ProtocolIndicator.ACTOR;

  static bool isAddressSecp256k1(Address address) =>
      address.protocol == ProtocolIndicator.SECP256K1;

  static bool isAddressDelegate(Address address) =>
      address.protocol == ProtocolIndicator.DELEGATED;

  static bool isFilEthAddress(Address address) {
    return address is AddressDelegated && address.namespace == '10';
  }
}

class AddressId extends Address {
  late final String _id;
  AddressId(String networkPrefix, Uint8List payload) {
    if (payload.length > ID_PAYLOAD_MAX_LEN) {
      throw FilAddressError("Invalid ID address payload length");
    }
    _payload = payload;
    _networkPrefix = networkPrefix;
    _id = toString().substring(2);
    protocol = ProtocolIndicator.ID;
  }

  String get id => _id;

  static AddressId fromAddressString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    if (!validateNetworkPrefix(networkPrefix)) {
      throw FilAddressError("Invalid network prefix");
    }

    if (int.parse(protocolIndicator) != ProtocolIndicator.ID.index) {
      throw FilAddressError("Invalid protocol indicator");
    }
    final addressInt = int.tryParse(address.substring(2));
    if (addressInt == null) throw FilAddressError("Invalid address");
    final payload = Leb128.encodeUnsigned(addressInt);
    return AddressId(networkPrefix, payload);
  }

  String toEthAddressHex([bool hexPrefix = false]) {
    final payloadString = listToHex(_payload);
    return '${hexPrefix ? '0xff' : 'ff'}${payloadString.padLeft(ETH_ADDRESS_LEN * 2, '0')}';
  }

  @override
  String toString() =>
      networkPrefix +
      protocol.index.toString() +
      Leb128.decodeUnsigned(payload).toString();
}

class AddressActor extends Address {
  AddressActor(String networkPrefix, Uint8List payload) {
    _networkPrefix = networkPrefix;
    if (payload.length > ACTOR_PAYLOAD_LEN) {
      throw FilAddressError("Invalid Actor address payload length");
    }
    _payload = payload;
    protocol = ProtocolIndicator.ACTOR;
  }

  static AddressActor fromAddressString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    if (!validateNetworkPrefix(networkPrefix)) {
      throw FilAddressError("Invalid network prefix");
    }
    if (int.parse(protocolIndicator) != ProtocolIndicator.ACTOR.index) {
      throw FilAddressError("Invalid protocol indicator");
    }

    final decodedData = base32.decode(address.substring(2).toUpperCase());
    final payload = decodedData.sublist(0, decodedData.length - 4);
    final checksum = decodedData.sublist(decodedData.length - 4);

    final newAddress = AddressActor(networkPrefix, payload);
    if (listToHex(newAddress.getChecksum()) != listToHex(checksum)) {
      throw FilAddressError('Invalid checksum address');
    }
    return newAddress;
  }

  @override
  String toString() {
    final checksum = getChecksum();
    return networkPrefix +
        protocol.toString() +
        base32Encode(Uint8List.fromList(payload + checksum)).toLowerCase();
  }
}

class AddressBls extends Address {
  AddressBls(String networkPrefix, Uint8List payload) {
    _networkPrefix = networkPrefix;
    _payload = payload;
    if (payload.length > BLS_PAYLOAD_LEN) {
      throw FilAddressError("Invalid bls address payload length");
    }
    protocol = ProtocolIndicator.BLS;
  }

  static AddressBls fromAddressString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    if (!validateNetworkPrefix(networkPrefix)) {
      throw FilAddressError("Invalid network prefix");
    }
    if (int.parse(protocolIndicator) != ProtocolIndicator.BLS.index) {
      throw FilAddressError('Invalid proroocol indicator');
    }

    final decodedData = base32.decode(address.substring(2).toUpperCase());
    final payload = decodedData.sublist(0, decodedData.length - 4);
    final checksum = decodedData.sublist(decodedData.length - 4);

    final newAddress = AddressBls(networkPrefix, payload);
    if (listToHex(newAddress.getChecksum()) != listToHex(checksum)) {
      throw FilAddressError('Invalid checksum address');
    }
    return newAddress;
  }

  @override
  String toString() {
    final checksum = getChecksum();
    return networkPrefix +
        protocol.index.toString() +
        base32Encode(Uint8List.fromList(payload + checksum)).toLowerCase();
  }
}

class AddressSecp256k1 extends Address {
  AddressSecp256k1(String networkPrefix, Uint8List payload) {
    _networkPrefix = networkPrefix;
    _payload = payload;
    protocol = ProtocolIndicator.SECP256K1;
  }

  static AddressSecp256k1 fromAddressString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    if (!validateNetworkPrefix(networkPrefix)) {
      throw FilAddressError("Invalid network prefix");
    }
    if (int.tryParse(protocolIndicator) != 1) {
      throw FilAddressError('Invalid proroocol indicator');
    }

    final decodedData = base32.decode(address.substring(2).toUpperCase());
    final payload = decodedData.sublist(0, decodedData.length - 4);
    final checksum = decodedData.sublist(decodedData.length - 4);

    final newAddress = AddressSecp256k1(networkPrefix, payload);
    if (listToHex(newAddress.getChecksum()) != listToHex(checksum)) {
      throw FilAddressError('Invalid checksum address');
    }
    return newAddress;
  }

  @override
  String toString() {
    final checksum = getChecksum();
    return networkPrefix +
        protocol.index.toString() +
        base32Encode(Uint8List.fromList(payload + checksum)).toLowerCase();
  }
}

class AddressDelegated extends Address {
  late String _namespace;
  late Uint8List _subAddress;
  AddressDelegated(
      String networkPrefix, String namespace, Uint8List subAddress) {
    _networkPrefix = networkPrefix;
    if (BigInt.parse(namespace) > ID_PAYLOAD_MAX_NUM) {
      throw FilAddressError('Invalid namespace');
    }
    if (subAddress.isEmpty || subAddress.length > SUB_ADDRESS_MAX_LEN) {
      throw FilAddressError('Invalid sub address length');
    }
    _namespace = namespace;
    _subAddress = subAddress;
    protocol = ProtocolIndicator.DELEGATED;
    _payload = toBytes().sublist(1);
  }

  String get namespace => _namespace;
  Uint8List get subAddress => _subAddress;

  static AddressDelegated fromAddressString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];

    if (!validateNetworkPrefix(networkPrefix)) {
      throw FilAddressError("Invalid network prefix");
    }
    if (int.tryParse(protocolIndicator) != 4) {
      throw FilAddressError('Invalid proroocol indicator');
    }
    final namespace = address.substring(2, address.indexOf('f', 2));
    final decodedData = base32
        .decode(address.substring(address.indexOf('f', 2) + 1).toUpperCase());
    final subAddress = decodedData.sublist(0, decodedData.length - 4);
    final checksum = decodedData.sublist(decodedData.length - 4);

    final newAddress = AddressDelegated(networkPrefix, namespace, subAddress);
    if (listToHex(newAddress.getChecksum()) != listToHex(checksum)) {
      throw FilAddressError('Invalid checksum address');
    }
    return newAddress;
  }

  @override
  Uint8List toBytes() {
    final namespaceBytes = Leb128.encodeUnsigned(int.parse(namespace));
    final protocolBytes = Leb128.encodeUnsigned(protocol.index);

    return Uint8List.fromList(protocolBytes + namespaceBytes + _subAddress);
  }

  @override
  String toString() {
    final checksum = getChecksum();
    return ('$networkPrefix${protocol.index}${_namespace}f${base32Encode(Uint8List.fromList(_subAddress + checksum)).toLowerCase()}');
  }
}

class FilEthAddress extends Address {
  ProtocolIndicator protocolIndicator = ProtocolIndicator.DELEGATED;
  late Uint8List _subAddress;
  final nameSpace = 10;

  FilEthAddress(String networkPrefix, Uint8List ethAddress) {
    _networkPrefix = networkPrefix;
    _subAddress = ethAddress;
    _payload = toBytes().sublist(1);
    protocol = ProtocolIndicator.DELEGATED;
  }
  @override
  Uint8List toBytes() {
    final namespaceBytes = Leb128.encodeUnsigned(nameSpace);
    final protocolBytes = Leb128.encodeUnsigned(4);

    return Uint8List.fromList(protocolBytes + namespaceBytes + _subAddress);
  }

  /// Convert to f4 address.
  @override
  String toString() {
    final checksum = getChecksumForPayload(toBytes());
    return '$networkPrefix${protocol.index}${nameSpace}f${base32Encode(Uint8List.fromList(_subAddress + checksum)).toLowerCase()}';
  }

  /// FilEthAddress from f4 address.
  static FilEthAddress fromString(String address) {
    final networkPrefix = address[0];
    final protocolIndicator = address[1];
    if (int.parse(protocolIndicator) != 4) throw Error();
    final dataEncoded = address.substring(address.indexOf('f', 2) + 1);
    final dataDecoded = base32.decode(dataEncoded.toUpperCase());
    final subAddress = dataDecoded.sublist(0, dataDecoded.length - 4);
    final newAddress = FilEthAddress(networkPrefix, subAddress);
    return newAddress;
  }

  /// FilEthAddress from evm address, 0x prefixed.
  static FilEthAddress fromEthString(String address, [networkPrefix = 'f']) {
    final ethAddress = hexToUint8List(address);
    return FilEthAddress(networkPrefix, ethAddress);
  }

  /// Convert to eth string.
  String toEthString([hexPrefix = true]) {
    return '${hexPrefix ? '0x' : ''}${_subAddress.map((int a) => a.toRadixString(16).padLeft(2, '0')).join('')}';
  }
}
