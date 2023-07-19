typedef EventData = Map<String, dynamic>;
typedef EventHandler = Function(EventData data);

/// An helper class that gives ability for class
/// which extends this to work as `Event-Driven` based class
abstract class EventEmitter {
  final _eventHandlers = <String, List<EventHandler>>{};

  /// Get a list of [EventHandler] based on the [event].
  List<EventHandler> _getHandlers(String event) {
    return _eventHandlers.putIfAbsent(event, () => []);
  }

  /// Add a [handler] for an [event], which will be
  /// invoked everytime for the changes occur on that
  /// event.
  void on(String event, EventHandler handler) {
    _getHandlers(event).add(handler);
  }

  /// Removes the [handler] for an [event], which is added
  /// before via [on] method.
  ///
  /// Returns `true` if the [handler] is removed,
  /// Else returns `false` if not removed
  bool off(String event, EventHandler handler) {
    return _getHandlers(event).remove(handler);
  }

  /// Similar to the [on] method but the only difference
  /// was [handler] will be invoked once & removed
  /// automatically by calling [off] method internally
  /// after invoking
  void once(String event, EventHandler handler) {
    void customHandler(EventData data) {
      handler(data);
      off(event, customHandler);
    }

    on(event, customHandler);
  }

  /// Emits the [data] under an [event].
  /// Which will includes invoking all the [EventHandler]'s
  /// registered under that [event].
  void emit(String event, EventData data) {
    final handlers = _getHandlers(event);
    // Emit in the reverse order of added eventHandlers,
    // this is needed otherwise we will get into
    // `Concurrent modification during iteration` error
    for (int i = handlers.length - 1; i >= 0; --i) {
      handlers.elementAt(i).call(data);
    }
  }
}
