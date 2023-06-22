import 'dart:typed_data';

import 'multipart_form_data.dart';

/// Holds the file that came via `ContentTypes.kMultipartFormData`
class MultipartFile extends MultipartFormData {
  @override
  final Uint8List value;

  final String name;
  final String contentType;

  const MultipartFile(
    String key,
    this.value,
    this.name,
    this.contentType,
  ) : super(key);
}
