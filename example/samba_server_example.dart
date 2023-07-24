import 'dart:async';

import 'package:samba_server/samba_server.dart';

class ChatSocketRoute extends WebSocketRoute {
  @override
  FutureOr<void> onConnected(WebSocket webSocket) {
    throw UnimplementedError();
  }
}

class HelloRoute extends Route {
  HelloRoute() : super(HttpMethod.get, '/');

  @override
  FutureOr<Response> handler(Request request) {
    return Response.ok(body: 'Hello from SAMBA_SERVER');
  }
}

Future<void> main() async {
  final httpServer = HttpServer();
  httpServer
    ..registerRoute(HelloRoute())
    ..registerRoute(ChatSocketRoute());
  await httpServer.bind(address: '127.0.0.1', port: 8080);
}
