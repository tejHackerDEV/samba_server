import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:samba_server/src/extensions/map_extension.dart';

import '../../../utils/content_types.dart';
import 'request_decoder.dart';
import 'string_request_decoder.dart';

class FormUrlencodedRequestDecoder
    extends RequestDecoder<Map<String, dynamic>> {
  /// An interceptor to decode body of a request which contains `content-type`
  /// as [ContentType.kFormUrlencoded] in request headers.
  ///
  /// In order to decode the body correctly, one should pass correct
  /// [encoding] strategy used in encoding the request body.
  const FormUrlencodedRequestDecoder({
    Encoding fallbackEncoding = utf8,
  }) : super(
          contentType: ContentTypes.kFormUrlencoded,
          fallbackEncoding: fallbackEncoding,
        );

  @override
  FutureOr<Map<String, dynamic>> decode(
    io.ContentType contentType,
    Encoding encoding,
    Stream<Uint8List> stream,
  ) async {
    return _splitQueryString(
      await StringRequestDecoder(fallbackEncoding: fallbackEncoding).decode(
        contentType,
        encoding,
        stream,
      ),
      encoding: fallbackEncoding,
    );
  }

  /// An modified version of original [Uri.splitQueryString] where
  /// the original function will return [Map<String, String>] but
  /// this modified version of ours will return [Map<String, dynamic>]
  /// where [dynamic] value can be a [String] or [List<String>]
  Map<String, dynamic> _splitQueryString(
    String query, {
    required Encoding encoding,
  }) {
    return query.split("&").fold({}, (map, element) {
      int index = element.indexOf("=");
      if (index == -1) {
        if (element != "") {
          map[Uri.decodeQueryComponent(element, encoding: encoding)] = "";
        }
      } else if (index != 0) {
        final key = Uri.decodeQueryComponent(
          element.substring(0, index),
          encoding: encoding,
        );
        final value = Uri.decodeQueryComponent(
          element.substring(index + 1),
          encoding: encoding,
        );
        map.addOrUpdateValue(key: key, value: value);
      }
      return map;
    });
  }
}
