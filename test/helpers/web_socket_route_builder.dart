import 'dart:async';

import 'package:samba_server/samba_server.dart';

class WebSocketRouteBuilder extends WebSocketRoute {
  final Iterable<Interceptor> Function(Request request)? interceptorsBuilder;

  final FutureOr<void> Function(WebSocket webSocket) connectedHandler;

  final FutureOr<void> Function(
    WebSocket webSocket,
    Object error,
    StackTrace stackTrace,
  )? errorHandler;

  final FutureOr<WebSocketResponse> Function(WebSocketResponse response)?
      doneHandler;

  WebSocketRouteBuilder(
    super.path, {
    this.interceptorsBuilder,
    required this.connectedHandler,
    this.errorHandler,
    this.doneHandler,
  });

  @override
  Iterable<Interceptor>? interceptors(Request request) =>
      interceptorsBuilder?.call(request);

  @override
  FutureOr<void> onConnected(WebSocket webSocket) =>
      connectedHandler(webSocket);

  @override
  FutureOr<void> onError(
    WebSocket webSocket,
    Object error,
    StackTrace stackTrace,
  ) =>
      errorHandler?.call(
        webSocket,
        error,
        stackTrace,
      );

  @override
  FutureOr<WebSocketResponse> onDone(WebSocketResponse response) {
    if (doneHandler != null) {
      return doneHandler!.call(response);
    }
    return super.onDone(response);
  }
}
