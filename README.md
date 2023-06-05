# Filecoin Address

## Usage

Eth address to f4 address
```dart
final address = '0xd4c5fb16488aa48081296299d54b0c648c9333da';
final ethAddress = FilEthAddress.fromEthString(address);
print(ethAddress.toString());
```

f4 address to Eth address
```dart
final address = 'f410f2tc7wfsirksibajjmkm5ksymmsgjgm62hjnomwa';
final ethAddress = FilEthAddress.fromString(address);
print(ethAddress.toEthString());
```