import 'dart:async';

import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/status.dart' as web_socket_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/interceptor_builder.dart';
import '../helpers/web_socket_route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpServer = HttpServer();

  setUp(() async => await httpServer.bind(address: address, port: port));

  tearDown(() async => await httpServer.shutdown());

  group('Connection tests', () {
    test('Should able to connect to the websocket', () async {
      final completer = Completer<bool>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          completer.complete(true);
        },
        errorHandler: (_, error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      final webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      await webSocketChannel.ready;
      expect(await completer.future, isTrue);
      expect(webSocketRouteBuilder.clients.length, 1);
    });

    test('Should able to disconnect the websocket', () async {
      final completer = Completer<bool>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (_) {},
        errorHandler: (_, error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
        doneHandler: (webSocketResponse) {
          completer.complete(true);
          return webSocketResponse;
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      final webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      await webSocketChannel.ready;
      expect(webSocketRouteBuilder.clients.length, 1);
      await webSocketChannel.sink.close(web_socket_status.goingAway);
      expect(await completer.future, isTrue);
      expect(webSocketRouteBuilder.clients.length, 0);
    });

    test(
        'Should able to disconnect the websocket even by sending normal response',
        () async {
      final completer = Completer<bool>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
          connectedHandler: (_) {},
          errorHandler: (_, error, stackTrace) {
            completer.completeError(error, stackTrace);
          },
          doneHandler: (webSocketResponse) {
            completer.complete(true);
            return webSocketResponse;
          },
          interceptorsBuilder: (_) => [
                InterceptorBuilder(onDisposeHandler: (_, __) {
                  return Response.ok();
                }),
              ]);
      httpServer.registerRoute(webSocketRouteBuilder);
      final webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      await webSocketChannel.ready;
      expect(webSocketRouteBuilder.clients.length, 1);
      await webSocketChannel.sink.close(web_socket_status.goingAway);
      expect(await completer.future, isTrue);
      expect(webSocketRouteBuilder.clients.length, 0);
    });
  });
}
