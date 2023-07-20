import 'dart:async';
import 'dart:io' as io;

import '../helpers/enums/index.dart';
import '../interceptor/index.dart';
import '../request.dart';
import '../response.dart';
import '../router/index.dart';
import 'event_emitter.dart';
import 'web_socket.dart';
import 'web_socket_response.dart';

abstract class WebSocketRoute extends EventEmitter implements Route {
  @override
  final HttpMethod httpMethod = HttpMethod.get;

  @override
  final String path;

  /// Stores all the clients that has connected to this route
  final _clientMap = <String, WebSocket>{};

  WebSocketRoute(this.path);

  @override
  Iterable<Interceptor>? interceptors(Request request) => null;

  /// An handler that will get triggered, when ever new client
  /// is connected to the route
  FutureOr<void> onConnected(WebSocket webSocket);

  /// An handler that will be triggered, when ever any error
  /// occurred for a particular client
  FutureOr<void> onError(
    WebSocket webSocket,
    Object error,
    StackTrace stackTrace,
  ) {}

  /// An handler that will get triggered, when ever new client
  /// got disconnected from the route
  FutureOr<WebSocketResponse> onDone(WebSocketResponse response) {
    return response;
  }

  @override
  FutureOr<Response> handler(Request request) async {
    final ioWebSocket = await io.WebSocketTransformer.upgrade(
      request.ioHttpRequest,
    );
    final completer = Completer<WebSocketResponse>();
    final webSocket = WebSocket(ioWebSocket, onDone: (webSocket) {
      _onDone(
        webSocket,
        completer: completer,
        ioHttpResponse: request.ioHttpRequest.response,
      );
    });
    runZonedGuarded(() {
      // Store the client
      _clientMap[webSocket.id] = webSocket;
      webSocket.listen();
      onConnected.call(webSocket);
    }, (error, stackTrace) {
      onError(webSocket, error, stackTrace);
    });
    return await completer.future.catchError((error, stackTrace) {
      return WebSocketResponse.error(
        webSocket,
        ioHttpResponse: request.ioHttpRequest.response,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Will be invoked, once a [WebSocket] client
  /// connection is completed.
  Future<void> _onDone(
    WebSocket webSocket, {
    required Completer<WebSocketResponse> completer,
    required io.HttpResponse ioHttpResponse,
  }) async {
    try {
      // remove the client
      _clientMap.remove(webSocket.id);
      final response = await onDone(
        WebSocketResponse(
          webSocket,
          ioHttpResponse: ioHttpResponse,
        ),
      );
      completer.complete(response);
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }

  /// Emits the [data] to client under particular [event]
  /// and return the ids of those `WebSocket`s to whom
  /// the it has been emitted.
  ///
  /// <br>
  /// By default emit the data to all [clients] connected
  /// to the server.
  ///
  /// <br>
  /// If [webSocketIds] is not null then data will be emitted
  /// only to those `WebSocket`s.
  ///
  /// <br>
  /// If [self] is `true` then [data] will also be emitted to the
  /// listeners present in the server listening to specified [event]
  /// including `WebSocket`s scope as well as `WebSocketRoute` scope.
  @override
  List<String> emit(
    String event,
    EventData data, {
    Iterable<String>? webSocketIds,
    bool toSelf = false,
  }) {
    final emittedTo = <String>[];
    // by default assume sending data to all
    bool emitToAll = true;

    void emitToWebSocket(WebSocket webSocket) {
      webSocket.emit(event, data, toSelf: toSelf);
      emittedTo.add(webSocket.id);
    }

    if (webSocketIds != null) {
      // as webSocketIds is populated only
      // send data to those
      emitToAll = false;
      for (final webSocketId in webSocketIds) {
        final webSocket = _clientMap[webSocketId];
        if (webSocket == null) {
          continue;
        }
        emitToWebSocket(webSocket);
      }
    }

    if (emitToAll) {
      for (var webSocket in clients) {
        emitToWebSocket(webSocket);
      }
    }

    if (toSelf) {
      super.emit(event, data);
    }
    return emittedTo;
  }

  Iterable<WebSocket> get clients => _clientMap.values;
}
