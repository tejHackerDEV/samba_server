import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'request_decoder.dart';

class StringRequestDecoder extends RequestDecoder<String> {
  /// An interceptor to decode body of a request whose `content-type`
  /// starts with `text/` in request headers.
  ///
  /// In order to decode the body correctly, one should pass correct
  /// [encoding] strategy used in encoding the request body.
  const StringRequestDecoder({
    Encoding fallbackEncoding = utf8,
  }) : super(
          contentType: 'text/',
          fallbackEncoding: fallbackEncoding,
        );

  @override
  FutureOr<String> decode(
    io.ContentType contentType,
    Encoding encoding,
    Stream<Uint8List> stream,
  ) {
    return encoding.decoder.bind(stream).join();
  }
}
