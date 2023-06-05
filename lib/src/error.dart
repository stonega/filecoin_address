import 'dart:developer';

class FilAddressError extends Error {
  final String? message;

  FilAddressError([this.message]);

  @override
  String toString() {
    log('[Filecoin address error] $message');
    return Error.safeToString(message).replaceAll('"', '');
  }
}
