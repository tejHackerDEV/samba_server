import '../../../utils/content_types.dart';
import 'response_encoder.dart';

class BoolResponseEncoder extends ResponseEncoder<bool> {
  const BoolResponseEncoder() : super(contentType: ContentTypes.kPlainText);

  @override
  String encode(bool value) {
    return value.toString();
  }
}
