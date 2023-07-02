import 'dart:convert';

import '../../../utils/content_types.dart';
import 'response_encoder.dart';

class JsonListResponseEncoder extends ResponseEncoder<Iterable<dynamic>> {
  const JsonListResponseEncoder() : super(contentType: ContentTypes.kJson);

  @override
  String encode(Iterable<dynamic> value) {
    return json.encode(value);
  }
}
