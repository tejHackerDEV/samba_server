import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import '../../../request.dart';
import '../../../response.dart';
import '../../interceptor.dart';

/// Used to create an decoder for the incoming request body,
/// based on the `content-type` passed in the request headers.
abstract class RequestDecoder<T extends Object> extends Interceptor {
  /// This value will be present in [Request] header
  final String contentType;

  /// This encoding will be used in-case the encoding is not recognized
  /// automatically from the [Request] `content-type` charset.
  final Encoding fallbackEncoding;

  const RequestDecoder({
    required this.contentType,
    required this.fallbackEncoding,
  }) : super();

  /// Returns `true` or `false` to determine whether this decoder can decode
  /// the target value or not
  bool canDecode(io.ContentType contentType) => contentType.value.startsWith(
        this.contentType,
      );

  /// Should have an implementation of converting the [stream] to type [T].
  ///
  /// <br>
  /// [contentType] is the type that is present inside the request
  FutureOr<T> decode(
    io.ContentType contentType,
    Encoding encoding,
    Stream<Uint8List> stream,
  );

  @override
  FutureOr<Response?> onInit(Request request) async {
    final contentType = request.contentType;
    final requestBody = request.body;
    if (requestBody is! Stream<Uint8List>) return null;
    if (contentType == null) return null;
    if (!canDecode(contentType)) return null;
    request.body = await decode(
      contentType,
      Encoding.getByName(contentType.charset) ?? fallbackEncoding,
      requestBody,
    );
    return null;
  }

  @override
  String toString() {
    return '$contentType decoder';
  }
}
