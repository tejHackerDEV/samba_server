import 'dart:io' as io;

import 'package:samba_server/src/extensions/io_http_request_extension.dart';

import 'helpers/enums/index.dart';

class Request {
  final io.HttpRequest ioHttpRequest;

  /// Indicates the type of method that the request is handling.
  final HttpMethod httpMethod;

  /// Headers that are passed in the request as key value paris.
  final Map<String, String> headers;

  const Request._(
    this.ioHttpRequest,
    this.httpMethod,
    this.headers,
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
      ioHttpRequest.extractHeaders(),
    );
  }

  /// The URI for the request.
  ///
  /// This provides access to the
  /// path and query string for the request.
  Uri get uri => ioHttpRequest.uri;
}
