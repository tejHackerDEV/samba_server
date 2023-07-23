import 'dart:convert';

import '../../../utils/content_types.dart';
import 'response_encoder.dart';

class JsonMapResponseEncoder extends ResponseEncoder<Map<String, dynamic>> {
  const JsonMapResponseEncoder() : super(contentType: ContentTypes.kJson);

  @override
  String encode(Map<String, dynamic> value) {
    return json.encode(value);
  }
}
