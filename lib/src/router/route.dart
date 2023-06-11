import 'typedefs.dart';

class Route {
  final String path;
  final RouteHandler handler;

  Route(this.path, this.handler);

  @override
  String toString() => path;

  /// Returns a new instance of [Route] with new properties passed.
  ///
  /// <br>
  /// If no properties passed then a new deep clone will be created
  /// on which the operation is performed.
  Route copyWith({
    String? path,
    RouteHandler? handler,
  }) =>
      Route(
        path ?? this.path,
        handler ?? this.handler,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Route && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
