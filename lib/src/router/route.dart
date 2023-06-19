import 'dart:async';

import '../helpers/enums/index.dart';
import '../interceptor/index.dart';
import '../request.dart';
import '../response.dart';

abstract class Route {
  final HttpMethod httpMethod;
  final String path;

  const Route(this.httpMethod, this.path);

  FutureOr<Response> handler(Request request);

  Iterable<Interceptor>? interceptors(Request request) => null;

  @override
  String toString() => path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Route && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
