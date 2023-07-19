import 'dart:io' as io;

extension IOHttpHeadersExtension on io.HttpHeaders {
  /// Extracts the headers in the key value format.
  /// In extraction process values will be reduced
  /// into a single string separated by comma(`,`).
  Map<String, String> toMap() {
    final Map<String, String> map = {};
    forEach((name, values) {
      map[name] = values.join(',');
    });
    return map;
  }
}
