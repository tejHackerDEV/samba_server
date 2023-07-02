import 'dart:io' as io;

import 'package:samba_server/src/extensions/io_http_request_extension.dart';

import 'helpers/enums/index.dart';

class Request {
  final io.HttpRequest ioHttpRequest;

  /// Indicates the type of method that the request is handling.
  final HttpMethod httpMethod;

  /// Holds the values of the dynamic parameters that were declared
  /// at the time of route registration in key-value pairs
  ///
  /// <br>
  /// `key` will be the name of the dynamic parameter that is declared
  /// at registration while `value` will be actual replacement of the `key`.
  final Map<String, String> pathParameters;

  /// Holds the values of the query parameters that were passed
  /// along with the request.
  ///
  /// Value of this map can be either a `String` or `List<String>`
  /// (in most cases).
  final Map<String, dynamic> queryParameters;

  /// Headers that are passed in the request as key value paris.
  final Map<String, String> headers;

  /// Body that has been passed in the request.
  ///
  /// <br>
  /// This will be a [Stream<List<int>>] by default unless
  /// converted by any `Interceptor` or `Route`.
  ///
  /// So before performing anything on this first check whether
  /// it is still a `Stream<Uint8List>` type or not.
  Object? body;

  Request._(
    this.ioHttpRequest,
    this.httpMethod,
    this.pathParameters,
    this.queryParameters,
    this.headers,
    this.body,
  );

  factory Request(io.HttpRequest ioHttpRequest) {
    final httpMethod = ioHttpRequest.extractHttpMethod();
    if (httpMethod == null) {
      // we don't support this method, so return throw an error.
      throw UnsupportedError(
        '${ioHttpRequest.method} httpMethod is not supported',
      );
    }
    return Request._(
      ioHttpRequest,
      httpMethod,
      {},
      {},
      ioHttpRequest.extractHeaders(),
      ioHttpRequest,
    );
  }

  /// The URI for the request.
  ///
  /// This provides access to the
  /// path and query string for the request.
  Uri get uri => ioHttpRequest.uri;

  io.ContentType? get contentType => ioHttpRequest.headers.contentType;

  /// Returns path along with any queryParameters if passed any
  String get completePath {
    final pathBuffer = StringBuffer(uri.path);
    if (uri.query.isNotEmpty) {
      pathBuffer
        ..write('?')
        ..write(uri.query);
    }
    return pathBuffer.toString();
  }
}
