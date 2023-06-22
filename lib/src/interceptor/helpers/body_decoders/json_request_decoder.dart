import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import '../../../utils/content_types.dart';
import 'request_decoder.dart';
import 'string_request_decoder.dart';

class JsonRequestDecoder extends RequestDecoder<Map<String, dynamic>> {
  /// An interceptor to decode body of a request which contains `content-type`
  /// as [ContentType.kJson] in request headers.
  ///
  /// In order to decode the body correctly, one should pass correct
  /// [encoding] strategy used in encoding the request body.
  const JsonRequestDecoder({
    Encoding fallbackEncoding = utf8,
  }) : super(
          contentType: ContentTypes.kJson,
          fallbackEncoding: fallbackEncoding,
        );

  @override
  FutureOr<Map<String, dynamic>> decode(
    io.ContentType contentType,
    Encoding encoding,
    Stream<Uint8List> stream,
  ) async {
    return jsonDecode(
      await StringRequestDecoder(fallbackEncoding: fallbackEncoding).decode(
        contentType,
        encoding,
        stream,
      ),
    );
  }
}
