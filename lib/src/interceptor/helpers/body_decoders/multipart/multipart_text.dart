import 'multipart_form_data.dart';

/// Holds the text that came via [ContentType.kMultipartFormData]
class MultipartText extends MultipartFormData {
  @override
  final String value;

  const MultipartText(String key, this.value) : super(key);
}
