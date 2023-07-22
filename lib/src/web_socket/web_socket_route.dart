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

abstract class WebSocketRoute extends Route {
  WebSocketRoute({
    String path = '/ws',
    HttpMethod httpMethod = HttpMethod.get,
  }) : super(httpMethod, path);

  /// Stores all the clients who were actively connected
  /// to this route at the moment
  final _clientMap = <String, WebSocket>{};

  /// Stores set of the `WebSocket` ids joined under
  /// a particular room at the moment.
  final _rooms = <String, Set<String>>{};

  @override
  Iterable<Interceptor>? interceptors(Request request) => null;

  /// An handler that will get triggered, when ever new client
  /// is connected to the route
  FutureOr<void> onConnected(WebSocket webSocket);

  /// An handler that will get triggered, when ever a new client
  /// joined a room
  FutureOr<void> onJoined(String room, WebSocket webSocket) {}

  /// An handler that will get triggered, when ever a client
  /// left a room
  FutureOr<void> onLeft(String room, WebSocket webSocket) {}

  /// An handler that will be triggered, when ever any error
  /// occurred for a particular client
  FutureOr<void> onError(
    WebSocket webSocket,
    Object error,
    StackTrace stackTrace,
  ) {}

  /// An handler that will get triggered, when ever client
  /// got disconnected from the route
  FutureOr<WebSocketResponse> onDone(WebSocketResponse response) {
    return response;
  }

  /// Gets the ids of the roomMates that were present
  /// in a particular room at the moment.
  Set<String> _getRoomMates(String room) {
    return _rooms.putIfAbsent(room, () => {});
  }

  /// Removes [webSocketId] from the specified [room]
  bool removeClientFromRoom(String room, String webSocketId) {
    final didLeft = _getRoomMates(room).remove(webSocketId);
    if (didLeft) {
      onLeft(room, _clientMap[webSocketId]!);
    }
    return didLeft;
  }

  @override
  FutureOr<Response> handler(Request request) async {
    final ioWebSocket = await io.WebSocketTransformer.upgrade(
      request.ioHttpRequest,
    );
    final completer = Completer<WebSocketResponse>();
    final webSocket = WebSocket(ioWebSocket, onJoin: (room, webSocket) {
      final didJoined = _getRoomMates(room).add(webSocket.id);
      if (didJoined) {
        onJoined(room, webSocket);
      }
      return didJoined;
    }, onLeave: (room, webSocket) {
      return removeClientFromRoom(room, webSocket.id);
    }, onDone: (webSocket) {
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
      // remove traces of client from everywhere
      for (final room in _rooms.keys) {
        removeClientFromRoom(room, webSocket.id);
      }
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
  /// to those `WebSocket`s instead of to all connected clients.
  ///
  /// <br>
  /// If [rooms] is not null then data will be emitted
  /// to those `WebSocket`s under those [rooms]
  /// instead of to all connected clients.
  ///
  /// <br>
  /// If [self] is `true` then [data] will also be emitted to the
  /// listeners present in the server listening to specified [event]
  List<String> emit(
    String event,
    EventData data, {
    Iterable<String>? webSocketIds,
    Iterable<String>? rooms,
    bool toSelf = false,
  }) {
    final emittedTo = <String>[];
    // by default assume sending data to all
    bool emitToAll = true;

    void emitToWebSocket(WebSocket webSocket) {
      webSocket.emit(event, data, toSelf: toSelf);
      emittedTo.add(webSocket.id);
    }

    void emitToWebSocketIds(Iterable<String> ids) {
      for (final webSocketId in ids) {
        final webSocket = _clientMap[webSocketId];
        if (webSocket == null) {
          continue;
        }
        emitToWebSocket(webSocket);
      }
    }

    if (webSocketIds != null) {
      // as webSocketIds is populated only
      // send data to those
      emitToAll = false;
      emitToWebSocketIds(webSocketIds);
    }

    if (rooms != null) {
      // as rooms is populated only
      // send data to those
      emitToAll = false;
      for (final room in rooms) {
        emitToWebSocketIds(_getRoomMates(room));
      }
    }

    if (emitToAll) {
      for (var webSocket in clients) {
        emitToWebSocket(webSocket);
      }
    }
    return emittedTo;
  }

  Iterable<WebSocket> get clients => _clientMap.values;

  Iterable<String> getRoomMates(String room) => _getRoomMates(room);
}
