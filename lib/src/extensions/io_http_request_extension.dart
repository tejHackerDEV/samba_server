import 'dart:io' as io;

extension IOHttpRequestExtension on io.HttpRequest {
  /// Extracts the headers in the key value format.
  /// In extraction process values will be reduced
  /// into a single string separated by comma(`,`).
  Map<String, String> extractHeaders() {
    final Map<String, String> map = {};
    headers.forEach((name, values) {
      map[name] = values.join(',');
    });
    return map;
  }
}
