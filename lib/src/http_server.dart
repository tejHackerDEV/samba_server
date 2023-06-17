import 'dart:io' as io;

import 'request.dart';
import 'router/index.dart';

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
      final request = Request(ioHttpRequest);
      try {
        final route = lookupRoute(request.httpMethod, request.uri.path);
        if (route == null) {
          // set statusCode as 404 because route not registered
          ioHttpRequest.response.statusCode = io.HttpStatus.notFound;
        } else {
          // route found so invoke it.
          final responseToSend = await route.handler(request);
          if (responseToSend != null) {
            ioHttpRequest.response.write(responseToSend);
          }
        }
      } on UnsupportedError catch (error) {
        ioHttpRequest.response.statusCode = io.HttpStatus.methodNotAllowed;
        ioHttpRequest.response.write(error);
      }
      // need to close response to send it back to the client
      return ioHttpRequest.response.close();
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
