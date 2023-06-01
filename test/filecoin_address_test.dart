import 'package:filecoin_address/filecoin_address.dart';
import 'package:filecoin_address/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Convert evm address', () {
    test('Checksum', () {
      final payload = '040ad4c5fb16488aa48081296299d54b0c648c9333da';
      final result = '3a5ae658';
      final hash = getChecksum(hexToUint8List(payload));
      expect(listToHex(hash), result);
    });
    test('Eth address to f4', () {
      final address = '0xd4c5fb16488aa48081296299d54b0c648c9333da';
      final ethAddress = FilEthAddress(hexToUint8List(address));
      expect(ethAddress.toString(),
          'f410f2tc7wfsirksibajjmkm5ksymmsgjgm62hjnomwa');
    });
    test('f4 to Eth address', () {
      final address = 'f410f2tc7wfsirksibajjmkm5ksymmsgjgm62hjnomwa';
      final ethAddress = FilEthAddress.fromString(address);
      expect(ethAddress.toString(), address);
      expect(
          ethAddress.toEthHex(), '0xd4c5fb16488aa48081296299d54b0c648c9333da');
    });
  });
}
