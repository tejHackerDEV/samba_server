import 'dart:io' as io;

import 'package:samba_server/src/extensions/io_http_request_extension.dart';

class Request {
  final io.HttpRequest ioHttpRequest;

  /// Headers that are passed in the request as key value paris.
  final Map<String, String> headers;

  const Request._(
    this.ioHttpRequest,
    this.headers,
  );

  factory Request(io.HttpRequest ioHttpRequest) {
    return Request._(
      ioHttpRequest,
      ioHttpRequest.extractHeaders(),
    );
  }

  /// The URI for the request.
  ///
  /// This provides access to the
  /// path and query string for the request.
  Uri get uri => ioHttpRequest.uri;
}
