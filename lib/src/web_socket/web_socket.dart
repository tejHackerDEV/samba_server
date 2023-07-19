import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:slugid/slugid.dart';

import 'event_emitter.dart';

const _kEventNameKey = 'name';
const _kEventDataKey = 'data';

class WebSocket extends EventEmitter {
  final io.WebSocket ioWebSocket;

  /// Will gets triggered, when ever `this` instance
  /// gets disconnected.
  final void Function(WebSocket) onDone;

  /// An uniqueId that is used to uniquely identify
  /// the current instance.
  final String id;

  WebSocket(
    this.ioWebSocket, {
    required this.onDone,
  }) : id = Slugid.v4().uuid();

  StreamSubscription? _streamSubscription;

  /// Indicates whether the websocket connection is active
  bool get isActive => _streamSubscription != null;

  /// Asserts whether the [ioWebSocket] connection is active
  void _assertSocketActive() {
    assert(isActive, 'WebSocket is not active to perform the action');
  }

  /// Once called all the incoming events will be listed
  /// for this webSocket, calling this function multiple times
  /// doesn't produce any side-effects, as this has been handled
  /// internally
  void listen() {
    if (isActive) {
      return;
    }
    _streamSubscription = ioWebSocket.listen(
      (rawEvent) {
        final event = jsonDecode(rawEvent);
        // Need to use `super` keyword otherwise
        // handlers will not be notified, because
        // we have overridden the `emit` function
        // in the current instance
        super.emit(event[_kEventNameKey], event[_kEventDataKey]);
      },
      onDone: () async {
        await _streamSubscription?.cancel();
        _streamSubscription = null;
        onDone(this);
      },
    );
  }

  @override
  void emit(String event, EventData data) {
    _assertSocketActive();
    if (!isActive) {
      return;
    }
    ioWebSocket.add(
      jsonEncode(
        {
          _kEventNameKey: event,
          _kEventDataKey: data,
        },
      ),
    );
  }

  /// Closes the connection of websocket,
  /// by sending the [code] & [reason]
  /// if specified
  void close({int? code, String? reason}) {
    _assertSocketActive();
    if (!isActive) {
      return;
    }
    ioWebSocket.close(code, reason);
  }
}
