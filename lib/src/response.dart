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

  void _initialize({
    Map<String, String>? headers,
  }) {
    if (headers != null) {
      this.headers.addAll(headers);
    }
  }

  /// Creates an instance from the [ioHttpResponse]
  Response.fromIO(io.HttpResponse ioHttpResponse)
      : statusCode = ioHttpResponse.statusCode,
        body = null {
    _initialize(headers: ioHttpResponse.headers.toMap());
  }

  /// Return response with `io.HttpStatus.ok` as [statusCode]
  Response.ok({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.ok {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.created` as [statusCode]
  Response.created({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.created {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.notFound` as [statusCode]
  Response.notFound({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.notFound {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.methodNotAllowed` as [statusCode]
  Response.methodNotAllowed({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.methodNotAllowed {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.noContent` as [statusCode]
  /// Also set the [body] as null along with [content-length] as `0`
  /// in the [headers]
  Response.noContent({
    Map<String, String>? headers,
  })  : statusCode = io.HttpStatus.noContent,
        body = null {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.internalServerError` as [statusCode]
  Response.internalServerError({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.internalServerError {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.unauthorized` as [statusCode]
  Response.unauthorized({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.unauthorized {
    _initialize(headers: headers);
  }

  /// Return response with `io.HttpStatus.forbidden` as [statusCode]
  Response.forbidden({
    Map<String, String>? headers,
    this.body,
  }) : statusCode = io.HttpStatus.forbidden {
    _initialize(headers: headers);
  }

  /// Return response with provided values
  Response({
    required this.statusCode,
    required this.body,
    Map<String, String>? headers,
  }) {
    _initialize(headers: headers);
  }
}
