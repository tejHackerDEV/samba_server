import 'dart:io' as io;

import '../response.dart';
import 'web_socket.dart';

/// An wrapper for [Response] class.
///
/// <br>
/// Note:- Changing anything in these class doesn't effect
/// the value that will be sent back to client.
/// It's purely for analytics purpose.
class WebSocketResponse extends Response {
  /// Instance of the client to whom `this` response belongs to
  final WebSocket webSocket;

  /// Holds any error that has occurred
  /// while doing the clean up process
  final Object? error;

  /// Holds the [StackTrace] of the [error] that has occurred
  final StackTrace? stackTrace;

  WebSocketResponse(
    this.webSocket, {
    required io.HttpResponse ioHttpResponse,
  })  : error = null,
        stackTrace = null,
        super.fromIO(ioHttpResponse);

  /// Creates an instance of response, which will
  /// which has the [error] & [stackTrace] populated.
  WebSocketResponse.error(
    this.webSocket, {
    required io.HttpResponse ioHttpResponse,
    required Object this.error,
    required StackTrace this.stackTrace,
  }) : super.fromIO(ioHttpResponse);
}
