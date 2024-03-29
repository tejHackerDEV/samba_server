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

  group('Listen events tests', () {
    test('Should able to listen to the events at server side', () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
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
      final eventData = {'id': 'userId'};
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
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
      final eventData = {'id': 'userId'};
      final completer = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
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

  group('Emit events tests', () {
    test(
        'Should able to emit to all connected clients by emitting via route (toSelf -> false)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          webSocket.on(eventName, (data) {
            throw UnsupportedError('Should not be triggered');
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          anotherCompleter.complete(event['data']);
        }
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(eventName, eventData);
      expect(emittedTo.length, 2);
      expect(
        emittedTo,
        webSocketRouteBuilder.clients.map((webSocket) => webSocket.id),
      );
      expect(await completer.future, eventData);
      expect(await anotherCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });

    test(
        'Should able to emit to all connected clients by emitting via route (toSelf -> true)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final webSocketCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketCompleter = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          webSocket.on(eventName, (data) {
            if (!webSocketCompleter.isCompleted) {
              webSocketCompleter.complete(data);
            } else {
              anotherWebSocketCompleter.complete(data);
            }
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          anotherCompleter.complete(event['data']);
        }
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo =
          webSocketRouteBuilder.emit(eventName, eventData, toSelf: true);
      expect(emittedTo.length, 2);
      expect(
        emittedTo,
        webSocketRouteBuilder.clients.map((webSocket) => webSocket.id),
      );
      expect(await completer.future, eventData);
      expect(await anotherCompleter.future, eventData);
      expect(await webSocketCompleter.future, eventData);
      expect(await anotherWebSocketCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });

    test(
        'Should able to emit only to specified socketIds instead of all via route (toSelf -> false)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      String? webSocketId;
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          webSocketId ??= webSocket.id;
          webSocket.on(eventName, (data) {
            throw UnsupportedError('Should not be triggered');
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        throw UnsupportedError('Should not be triggered');
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        webSocketIds: [webSocketId!],
      );
      expect(emittedTo.length, 1);
      expect(emittedTo, [webSocketId]);
      expect(await completer.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });

    test(
        'Should able to emit only to specified socketIds instead of all via route (toSelf -> true)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      String? webSocketId;
      final webSocketCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketCompleter = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          webSocketId ??= webSocket.id;
          webSocket.on(eventName, (data) {
            if (webSocket.id == webSocketId) {
              webSocketCompleter.complete(data);
            } else {
              anotherWebSocketCompleter.complete(data);
            }
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          anotherCompleter.complete(event['data']);
        }
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        webSocketIds: [webSocketId!],
        toSelf: true,
      );
      expect(emittedTo.length, 1);
      expect(emittedTo, [webSocketId]);
      expect(await completer.future, eventData);
      expect(await webSocketCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      expect(anotherWebSocketCompleter.isCompleted, isFalse);
      expect(anotherCompleter.isCompleted, isFalse);
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });
  });

  group('Emit events tests for rooms', () {
    test(
        'Should able to emit to clients only in a specific rooms via route (toSelf -> false)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final room1 = 'room1';
      final room1Mates = <String>[];
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          if (room1Mates.isEmpty) {
            room1Mates.add(webSocket.id);
            webSocket.join(room1);
          }
          webSocket.on(eventName, (data) {
            throw UnsupportedError('Should not be triggered');
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        throw UnsupportedError('Should not be triggered');
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        rooms: [room1],
      );
      expect(emittedTo.length, 1);
      expect(emittedTo, room1Mates);
      expect(await completer.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });

    test(
        'Should able to emit to clients only in a specific rooms via route (toSelf -> true)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final room1 = 'room1';
      final room1Mates = <String>[];
      final webSocketCompleter = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          if (room1Mates.isEmpty) {
            room1Mates.add(webSocket.id);
            webSocket.join(room1);
          }
          webSocket.on(eventName, (data) {
            if (!room1Mates.contains(webSocket.id)) {
              throw UnsupportedError('Should not be triggered');
            }
            webSocketCompleter.complete(data);
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        throw UnsupportedError('Should not be triggered');
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        rooms: [room1],
        toSelf: true,
      );
      expect(emittedTo.length, 1);
      expect(emittedTo, room1Mates);
      expect(await completer.future, eventData);
      expect(await webSocketCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
      ]);
    });
  });

  group('Combined emit events tests', () {
    test(
        'Should able to emit to clients only to the specified webSocketIds & rooms via route (toSelf -> false)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final room1 = 'room1';
      final room1Mates = <String>[];
      final nonRoom1Mates = <String>[];
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          if (room1Mates.isEmpty) {
            room1Mates.add(webSocket.id);
            webSocket.join(room1);
          } else if (nonRoom1Mates.isEmpty) {
            nonRoom1Mates.add(webSocket.id);
          }
          webSocket.on(eventName, (data) {
            throw UnsupportedError('Should not be triggered');
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherCompleter = Completer<Map<String, dynamic>>();
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          anotherCompleter.complete(event['data']);
        }
      });
      final oneMoreWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final oneMoreSubscription =
          oneMoreWebSocketChannel.stream.listen((rawEvent) {
        throw UnsupportedError('Should not be triggered');
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      await oneMoreWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        webSocketIds: nonRoom1Mates,
        rooms: [room1],
      );
      expect(emittedTo.length, 2);
      expect(emittedTo, [...nonRoom1Mates, ...room1Mates]);
      expect(await completer.future, eventData);
      expect(await anotherCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
        oneMoreSubscription.cancel(),
      ]);
    });

    test(
        'Should able to emit to clients only to the specified webSocketIds & rooms via route (toSelf -> true)',
        () async {
      final eventName = 'message';
      final eventData = {'id': 'userId'};
      final room1 = 'room1';
      final room1Mates = <String>[];
      final nonRoom1Mates = <String>[];
      final webSocketCompleter = Completer<Map<String, dynamic>>();
      final anotherWebSocketCompleter = Completer<Map<String, dynamic>>();
      final webSocketRouteBuilder = WebSocketRouteBuilder(
        connectedHandler: (webSocket) {
          if (room1Mates.isEmpty) {
            room1Mates.add(webSocket.id);
            webSocket.join(room1);
          } else if (nonRoom1Mates.isEmpty) {
            nonRoom1Mates.add(webSocket.id);
          }
          webSocket.on(eventName, (data) {
            if (!nonRoom1Mates.contains(webSocket.id)) {
              anotherWebSocketCompleter.complete(data);
            } else {
              webSocketCompleter.complete(data);
            }
          });
        },
      );
      httpServer.registerRoute(webSocketRouteBuilder);
      webSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final completer = Completer<Map<String, dynamic>>();
      final subscription = webSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          completer.complete(event['data']);
        }
      });
      final anotherWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final anotherCompleter = Completer<Map<String, dynamic>>();
      final anotherSubscription =
          anotherWebSocketChannel.stream.listen((rawEvent) {
        final event = jsonDecode(rawEvent);
        if (event['name'] == eventName) {
          anotherCompleter.complete(event['data']);
        }
      });
      final oneMoreWebSocketChannel = WebSocketChannel.connect(
        Uri.parse('ws://$address:$port/ws'),
      );
      final oneMoreSubscription =
          oneMoreWebSocketChannel.stream.listen((rawEvent) {
        throw UnsupportedError('Should not be triggered');
      });
      await webSocketChannel.ready;
      await anotherWebSocketChannel.ready;
      await oneMoreWebSocketChannel.ready;
      final emittedTo = webSocketRouteBuilder.emit(
        eventName,
        eventData,
        webSocketIds: nonRoom1Mates,
        rooms: [room1],
        toSelf: true,
      );
      expect(emittedTo.length, 2);
      expect(emittedTo, [...nonRoom1Mates, ...room1Mates]);
      expect(await completer.future, eventData);
      expect(await anotherCompleter.future, eventData);
      expect(await webSocketCompleter.future, eventData);
      expect(await anotherWebSocketCompleter.future, eventData);
      await Future.delayed(const Duration(seconds: 5));
      await Future.wait([
        subscription.cancel(),
        anotherSubscription.cancel(),
        oneMoreSubscription.cancel(),
      ]);
    });
  });
}
