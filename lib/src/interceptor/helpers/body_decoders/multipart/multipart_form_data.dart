/// An super class that can hold both file & text that came via
/// `ContentTypes.kMultipartFormData`
abstract class MultipartFormData {
  final String key;

  const MultipartFormData(this.key);

  Object get value;

  @override
  String toString() {
    return value.toString();
  }
}
