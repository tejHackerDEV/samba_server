import 'dart:async';
import 'dart:convert';

import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/status.dart' as web_socket_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/web_socket_route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpServer = HttpServer();

  late WebSocketChannel webSocketChannel;

  setUp(() async => await httpServer.bind(address: address, port: port));

  tearDown(() async {
    await webSocketChannel.sink.close(web_socket_status.goingAway);
    await httpServer.shutdown();
  });

  group('Listen Events tests', () {
    test('Should able to listen to the events at server side', () async {
      final eventName = 'message';
      final eventData = {
        'id': 'userId',
      };
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        '/ws',
        connectedHandler: (webSocket) {
          webSocket.on(eventName, (data) {
            completer.complete(data);
          });
        },
        errorHandler: (_, error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      await webSocketChannel.ready;
      webSocketChannel.sink.add(
        jsonEncode({
          'name': eventName,
          'data': eventData,
        }),
      );
      expect(await completer.future, eventData);
    });

    test(
        'Should not able to listen to the non-registered events at server side',
        () async {
      final eventName = 'message';
      final eventData = {
        'id': 'userId',
      };
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        '/ws',
        connectedHandler: (webSocket) {
          webSocket.on(eventName.toUpperCase(), (data) {
            completer.complete(data);
          });
        },
        errorHandler: (_, error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      await webSocketChannel.ready;
      webSocketChannel.sink.add(
        jsonEncode({
          'name': eventName,
          'data': eventData,
        }),
      );
      await Future.delayed(const Duration(seconds: 5));
      expect(completer.isCompleted, isFalse);
    });

    test('Should able to listen to the events at client side', () async {
      final eventName = 'message';
      final eventData = {
        'id': 'userId',
      };
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        '/ws',
        connectedHandler: (webSocket) {
          webSocket.emit(eventName, eventData);
        },
        errorHandler: (_, error, stackTrace) {
          completer.completeError(error, stackTrace);
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      await webSocketChannel.ready;
      expect(await completer.future, eventData);
      await subscription.cancel();
    });
  });
}
