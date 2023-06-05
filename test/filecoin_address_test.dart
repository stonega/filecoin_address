import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:filecoin_address/filecoin_address.dart';
import 'package:filecoin_address/src/utils.dart';

class AddressData {
  String bytes;
  String string;
  String network;
  int protocol;
  String payload;
  AddressData({
    required this.bytes,
    required this.string,
    required this.network,
    required this.protocol,
    required this.payload,
  });

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'bytes': bytes});
    result.addAll({'string': string});
    result.addAll({'network': network});
    result.addAll({'protocol': protocol});
    result.addAll({'payload': payload});

    return result;
  }

  factory AddressData.fromMap(Map<String, dynamic> map) {
    return AddressData(
      bytes: map['bytes'] ?? '',
      string: map['string'] ?? '',
      network: map['network'] ?? '',
      protocol: map['protocol']?.toInt() ?? 0,
      payload: map['payload'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AddressData.fromJson(String source) =>
      AddressData.fromMap(json.decode(source));
}

void main() {
  group('Convert evm address', () {
    test('Checksum', () {
      final payload = '040ad4c5fb16488aa48081296299d54b0c648c9333da';
      final result = '3a5ae658';
      final hash = getChecksumForPayload(hexToUint8List(payload));
      expect(listToHex(hash), result);
    });
    test('Eth address to f4', () {
      final address = '0xd4c5fb16488aa48081296299d54b0c648c9333da';
      final ethAddress = FilEthAddress.fromEthString(address);
      expect(ethAddress.toString(),
          'f410f2tc7wfsirksibajjmkm5ksymmsgjgm62hjnomwa');
    });
    test('f4 to Eth address', () {
      final address = 'f410f2tc7wfsirksibajjmkm5ksymmsgjgm62hjnomwa';
      final ethAddress = FilEthAddress.fromString(address);
      expect(ethAddress.toString(), address);
      expect(ethAddress.toEthString(),
          '0xd4c5fb16488aa48081296299d54b0c648c9333da');
    });
    test('Testnet', () {
      final addr = Address.fromString('t08666');
      expect(addr.toString(), 't08666');
      expect(listToHex(addr.toBytes()), '00da43');
      expect(addr.protocol, ProtocolIndicator.ID);
      expect(addr.networkPrefix, 't');
      expect(Address.isAddressId(addr), true);
      if (addr is AddressId) expect(addr.id, '8666');
    });

    test('Mainnet', () {
      final addr = Address.fromString('f08666');
      expect(addr.toString(), 'f08666');
      expect(listToHex(addr.toBytes()), '00da43');
      expect(addr.protocol, ProtocolIndicator.ID);
      expect(addr.networkPrefix, 'f');
      expect(Address.isAddressId(addr), true);
      if (addr is AddressId) expect(addr.id, '8666');
    });
    test('Exceed max id (super big)', () {
      try {
        Address.fromString('t0111111111111111111111111');
      } catch (e) {
        expect(e.toString(), 'Invalid address');
      }
    });

    test('To ethereum address (ID)', () async {
      final addr = Address.fromString('f0101');
      if (addr is AddressId) {
        expect(addr.toEthAddressHex(true),
            '0xff00000000000000000000000000000000000065');
        expect(addr.toEthAddressHex(false),
            'ff00000000000000000000000000000000000065');
      }
    });
  });

  group("Vectors", () {
    group("fromString", () {
      final vectors = jsonDecode(File('test/addresses.json').readAsStringSync());
      final testAdressed = [for (final v in vectors) AddressData.fromMap(v)];
      for (var item in testAdressed) {
        test('formAddress', () {
          final addr = Address.fromString(item.string);
          expect(addr.toString(), item.string);
          expect(listToHex(addr.toBytes()), item.bytes);
          expect(addr.protocol.index, item.protocol);
          expect(addr.networkPrefix, item.network);
          expect(listToHex(addr.payload), item.payload);

          if (addr is AddressId) expect(addr.id, item.string.substring(2));
          if (addr is AddressDelegated) {
            expect(addr.namespace,
                item.string.substring(2, item.string.indexOf(item.network, 1)));
          }
        });
      }
    });
  });
}
