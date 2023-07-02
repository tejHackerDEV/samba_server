import 'dart:async';

import '../../../request.dart';
import '../../../response.dart';
import '../../../utils/headers.dart';
import '../../interceptor.dart';

/// Used to create an encoder for the outgoing response body,
/// based on the type that is passed as body.
abstract class ResponseEncoder<T> extends Interceptor {
  /// This will set as the header in the [Response]
  final String contentType;

  const ResponseEncoder({required this.contentType});

  /// Should have an custom implementation of
  /// converting the [value] of type [T] to [String].
  String encode(T value);

  /// Returns `true` or `false` to determine whether
  /// this encoder can encode the [value] or not
  bool canEncode(dynamic value) => value is T;

  @override
  FutureOr<Response> onDispose(Request request, Response response) {
    // only encode if the `content-type` is not set already
    // this is a check used to restrict response body
    // to be encoded by multiple encoders if defined
    if (response.headers[Headers.kContentType] == null) {
      if (canEncode(response.body)) {
        response
          ..headers[Headers.kContentType] = contentType
          ..body = encode(response.body as T);
      }
    }
    return response;
  }

  @override
  String toString() {
    return '$T encoder';
  }
}
