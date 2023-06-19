import 'dart:async';

import 'package:samba_server/samba_server.dart';

typedef RequestHandler = FutureOr<Response> Function(Request request);

class RouteBuilder extends Route {
  final Iterable<Interceptor> Function(Request request)? interceptorsBuilder;
  final RequestHandler routeHandler;

  const RouteBuilder(
    super.httpMethod,
    super.path, {
    this.interceptorsBuilder,
    required this.routeHandler,
  });

  @override
  FutureOr<Response> handler(Request request) => routeHandler(request);

  @override
  Iterable<Interceptor>? interceptors(Request request) =>
      interceptorsBuilder?.call(request);
}
