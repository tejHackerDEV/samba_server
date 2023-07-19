import 'dart:io' as io;

import 'package:samba_server/src/extensions/io_http_headers_extension.dart';

/// A minimalistic version of [io.HttpResponse] which will hide
/// the complexities of [io.HttpResponse] class.
class Response {
  /// This will be set as a status-code for the response.
  int statusCode;

  /// Key-Value pairs added into this will be sent to the client.
  final Map<String, Object> headers = {};

  /// This will be set as a body for the response.
  Object? body;

  /// Creates an instance from the [ioHttpResponse]
  Response.fromIO(io.HttpResponse ioHttpResponse)
      : statusCode = ioHttpResponse.statusCode,
        body = null {
    headers.addAll(ioHttpResponse.headers.toMap());
  }

  /// Return response with `io.HttpStatus.ok` as [statusCode]
  Response.ok({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.ok {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.created` as [statusCode]
  Response.created({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.created {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.notFound` as [statusCode]
  Response.notFound({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.notFound {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.methodNotAllowed` as [statusCode]
  Response.methodNotAllowed({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.methodNotAllowed {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.noContent` as [statusCode]
  /// Also set the [body] as null along with [content-length] as `0`
  /// in the [headers]
  Response.noContent({
    Map<String, String>? headers,
  })  : statusCode = io.HttpStatus.noContent,
        body = null {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.internalServerError` as [statusCode]
  Response.internalServerError({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.internalServerError {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.unauthorized` as [statusCode]
  Response.unauthorized({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.unauthorized {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with `io.HttpStatus.forbidden` as [statusCode]
  Response.forbidden({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.forbidden {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Return response with provided values
  Response({
    required this.statusCode,
    required this.body,
    Map<String, String>? headers,
  }) {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }
}
