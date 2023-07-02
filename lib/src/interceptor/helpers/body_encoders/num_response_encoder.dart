import '../../../utils/content_types.dart';
import 'response_encoder.dart';

class NumResponseEncoder extends ResponseEncoder<num> {
  const NumResponseEncoder() : super(contentType: ContentTypes.kPlainText);

  @override
  String encode(num value) {
    return value.toString();
  }
}
