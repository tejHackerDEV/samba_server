import 'dart:io' as io;

import 'helpers/index.dart';
import 'request.dart';
import 'response.dart';
import 'router/index.dart';
import 'utils/headers.dart';

class HttpServer with RouterMixin {
  /// Holds the underlying [io.HttpServer] instance.
  io.HttpServer? _ioHttpServer;

  /// Indicates whether the server is running or not
  bool get isRunning => _ioHttpServer != null;

  /// Returns the uri of the server
  Uri get uri {
    _assertServerRunning();
    final hostBuffer = StringBuffer();
    if (_ioHttpServer!.address.type == io.InternetAddressType.IPv6) {
      // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
      // URL ambiguity with the ":" in the address.
      hostBuffer
        ..write('[')
        ..write(_ioHttpServer!.address.address)
        ..write(']');
    } else {
      hostBuffer.write(_ioHttpServer!.address.address);
    }

    return Uri(
      scheme: 'http',
      host: hostBuffer.toString(),
      port: _ioHttpServer!.port,
    );
  }

  /// Asserts whether the [_ioHttpServer] is not null
  void _assertServerRunning() {
    assert(isRunning, 'Server is not running to perform the action');
  }

  /// Starts listening for incoming requests
  void _listerForIncomingRequests() {
    _assertServerRunning();
    _ioHttpServer!.listen((ioHttpRequest) async {
      final ioHttpResponse = ioHttpRequest.response;
      final request = Request(ioHttpRequest);
      Response response;
      switch (request.httpMethod) {
        case HttpMethod.get:
        case HttpMethod.put:
        case HttpMethod.patch:
        case HttpMethod.delete:
          response = Response.ok();
          break;
        case HttpMethod.post:
          response = Response.created();
          break;
      }
      try {
        final route = lookupRoute(request.httpMethod, request.uri.path);
        if (route == null) {
          // set statusCode as 404 because route not registered
          ioHttpResponse.statusCode = io.HttpStatus.notFound;
        } else {
          // route found so invoke the handler.
          response = await route.handler(request, response);
          ioHttpResponse.statusCode = response.statusCode;
          response.headers.forEach((key, value) {
            ioHttpResponse.headers.set(key, value);
          });
          /**
           * Only write the body, if the statusCode is not equal `noContent`.
           * If its equal then don't write any body & set `content-length` as 0.
           * If we failed to do so, then we get below error.
           *
           * stackTrace
           * ```
           * Unhandled exception:
           * HttpException: Content size exceeds specified contentLength.
           * ```
           */
          if (response.statusCode == io.HttpStatus.noContent) {
            ioHttpResponse.headers.add(Headers.kContentLength, 0);
          } else {
            /**
             * After writing the body don't add or tamper anything
             * because if we failed to do so then we will
             * end up triggering an exception.
             *
             * stackTrace
             * ```
             * Bad state: Header already sent
             * ```
             */
            ioHttpResponse.write(response.body);
          }
        }
      } on UnsupportedError catch (error) {
        ioHttpResponse.statusCode = io.HttpStatus.methodNotAllowed;
        ioHttpResponse.write(error);
      }
      // need to close response to send it back to the client
      return ioHttpResponse.close();
    });
  }

  /// Internally calls [io.HttpServer.bind] & all the arguments passed
  /// to this function are the one exposed by [io.HttpServer.bind] function.
  Future<void> bind({
    required dynamic address,
    required int port,
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  }) async {
    if (isRunning) {
      throw AssertionError(
        'Server is already bind to port ${_ioHttpServer!.port}. So cant bind it again to port $port',
      );
    }
    _ioHttpServer = await io.HttpServer.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
    _listerForIncomingRequests();
  }

  /// Permanently stops this [HttpServer] from listening for new
  /// connections. This closes the [Stream] of [HttpRequest]s with a
  /// done event. The returned future completes when the server is
  /// stopped. For a server started using [bind] or [bindSecure] this
  /// means that the port listened on no longer in use.
  ///
  /// If [gracefully] is `false`, active connections will be closed immediately.
  Future<void> shutdown({bool gracefully = true}) async {
    _assertServerRunning();
    await _ioHttpServer?.close(
      force: gracefully,
    );
    _ioHttpServer = null;
  }
}
