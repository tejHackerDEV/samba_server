import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import '../../../utils/content_types.dart';
import 'request_decoder.dart';

class StringRequestDecoder extends RequestDecoder<String> {
  /// An interceptor to decode body of a request which contains `content-type`
  /// as [ContentTypes.kPlainText] in request headers.
  ///
  /// In order to decode the body correctly, one should pass correct
  /// [encoding] strategy used in encoding the request body.
  const StringRequestDecoder({
    Encoding fallbackEncoding = utf8,
  }) : super(
          contentType: ContentTypes.kPlainText,
          fallbackEncoding: fallbackEncoding,
        );

  @override
  bool canDecode(io.ContentType contentType) => contentType.value.startsWith(
        'text/',
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
