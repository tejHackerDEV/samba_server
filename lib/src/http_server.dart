import 'dart:io' as io;

class HttpServer {
  /// Holds the underlying [io.HttpServer] instance.
  io.HttpServer? _ioHttpServer;

  /// Indicates whether the server is running or not
  bool get isRunning => _ioHttpServer != null;

  /// Asserts whether the [_ioHttpServer] is not null
  void _assertServerRunning() {
    assert(isRunning, 'Server is not running to perform the action');
  }

  /// Starts listening for incoming requests
  void _listerForIncomingRequests() {
    _assertServerRunning();
    _ioHttpServer!.listen((ioHttpRequest) async {
      ioHttpRequest.response.write('Hello from SAMBA_SERVER');
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
