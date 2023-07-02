import '../../../utils/content_types.dart';
import 'response_encoder.dart';

class StringResponseEncoder extends ResponseEncoder<String> {
  const StringResponseEncoder() : super(contentType: ContentTypes.kPlainText);

  @override
  String encode(String value) {
    return value;
  }
}
