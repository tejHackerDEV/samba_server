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
  /// tries to join in a particular room.
  final bool Function(String, WebSocket) onJoin;

  /// Will gets triggered, when ever `this` instance
  /// tries to leave from a particular room.
  final bool Function(String, WebSocket) onLeave;

  /// Will gets triggered, when ever `this` instance
  /// gets disconnected.
  final void Function(WebSocket) onDone;

  /// An uniqueId that is used to uniquely identify
  /// the current instance.
  final String id;

  WebSocket(
    this.ioWebSocket, {
    required this.onJoin,
    required this.onLeave,
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

  /// Emits the [data] to client under particular [event].
  ///
  /// <br>
  /// If [self] is `true` then [data] will also be emitted to the
  /// listeners present in the server listening to specified [event]
  @override
  void emit(String event, EventData data, {bool toSelf = false}) {
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
    if (!toSelf) {
      return;
    }
    super.emit(event, data);
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

  /// Joins into the specified [room]
  bool join(String room) {
    return onJoin(room, this);
  }

  /// Removes from the specified [room]
  bool leave(String room) {
    return onLeave(room, this);
  }
}
