import 'dart:convert';

import 'package:samba_server/src/extensions/map_extension.dart';

extension StringExtension on String {
  /// An modified version of original [Uri.splitQueryString] where
  /// the original function will return `Map<String, String>` but
  /// this modified version of ours will return `Map<String, dynamic>`
  /// where `dynamic` value can be a `String` or `List<String>`.
  Map<String, dynamic> toQueryParameters({
    Encoding encoding = utf8,
  }) {
    // first check if the string is a full path or not,
    // by looking for the index of '?', because queryParameters stars with '?'
    int index = indexOf('?');
    if (index == -1) {
      // '?' didn't found in the string, so treat the complete string
      // from starting as a queryParameters
      index = 0;
    }
    return substring(index).split('&').fold({}, (map, element) {
      int index = element.indexOf('=');
      String? key;
      String? value;
      if (index == -1) {
        if (element != '') {
          key = Uri.decodeQueryComponent(element, encoding: encoding);
          value = '';
        }
      } else if (index != 0) {
        key = Uri.decodeQueryComponent(
          element.substring(0, index),
          encoding: encoding,
        );
        value = Uri.decodeQueryComponent(
          element.substring(index + 1),
          encoding: encoding,
        );
      }
      if (key != null) {
        map.addOrUpdateValue(key: key, value: value);
      }
      return map;
    });
  }
}
